module RuneRb::World
  # A World object models a virtual game world.
  class World
    attr :players
    attr :npcs
    attr :region_manager
    attr :event_manager
    attr :shop_manager
    attr :door_manager
    attr :object_manager
    attr :loader
    attr :work_thread

    def initialize
      @players = []
      @npcs = []
      @region_manager = RuneRb::Model::RegionManager.new
      @event_manager = RuneRb::Engine::EventManager.new
      @loader = YAMLFileLoader.new
      @task_thread = RuneRb::Misc::ThreadPool.new(1)
      @work_thread = RuneRb::Misc::ThreadPool.new(1)
      @shop_manager = RuneRb::Shops::ShopManager.new
      @object_manager = RuneRb::Objects::ObjectManager.new
      @door_manager = RuneRb::Doors::DoorManager.new
      register_global_events
    end

    def add_to_login_queue(session)
      submit_work {
        lr = @loader.check_login(session)
        response = lr.response

        # New login, so try loading profile
        if response == 2 && !@loader.load_profile(lr.player)
         response = 13
        end

        unless response == 2
          bldr = RuneRb::Net::PacketBuilder.new(-1, :RAW)
          bldr.add_byte response
          session.connection.send_data bldr.to_packet
          session.connection.close_connection true
        else
          session.player = lr.player
          submit_task {
            register lr.player
          }
        end
      }
    end

    def register(player)
      # Register
      player.index = (@players << player).index(player) + 1

      # Send login response
      bldr = RuneRb::Net::PacketBuilder.new(-1, :RAW)

      rights = RuneRb::World::RIGHTS.index(player.rights)
      bldr.add_byte 2
      bldr.add_byte (rights > 2 ? 2 : rights)
      bldr.add_byte 0

      player.connection.send_data bldr.to_packet

      HOOKS[:player_login].each {|k, v|
        begin
          v.call(player)
        rescue Exception => e
          RuneRb::World::PLUGIN_LOG.error "Unable to run login hook #{k}"
          RuneRb::World::PLUGIN_LOG.error e
        end
      }

      player.io.send_login
    end

    def unregister(player, single=true)
      if @players.include?(player)
        HOOKS[:player_logout].each {|k, v|
          begin
            v.call(player)
          rescue Exception => e
            RuneRb::World::PLUGIN_LOG.error "Unable to run logout hook #{k}"
            RuneRb::World::PLUGIN_LOG.error e
          end
        }

        player.destroy
        player.connection.close_connection_after_writing
        @players.delete(player) if single
		    submit_work {
		      @loader.save_profile(player)
		    }
		  end
    end

    def register_npc(npc)
      npc.index = (@npcs << npc).index(npc) + 1
    end

    def submit_task(&task)
      @task_thread.execute &task
    end

    def submit_work(&job)
      @work_thread.execute &job
    end

    def submit_event(event)
      @event_manager.submit event
    end

    private

    def register_global_events
      submit_event RuneRb::Tasks::UpdateEvent.new
      submit_event RuneRb::Objects::ObjectEvent.new
    end
  end

  class LoginResult
    attr_reader :response
    attr_reader :player

    def initialize(response, player)
      @response = response
      @player = player
    end
  end

  class Loader
    def check_login(session)
      raise "check_login not implemented"
    end

    def load_profile(player)
      raise "load_profile not implemented"
    end

    def save_profile(player)
      raise "save_profile not implemented"
    end
  end

  class YAMLFileLoader < Loader
    def check_login(session)
      # Check password validity
      unless validate_credentials(session.username, session.password)
        return LoginResult.new(3, nil)
      end

      existing = WORLD.players.find(nil) {|p| p.name.eql?(session.username)}

      if existing == nil
        # no existing user with this name, new login
        return LoginResult.new(2, RuneRb::Model::Player.new(session))
      else
        # existing user = already logged in
        return LoginResult.new(5, nil)
      end
    end

    def load_profile(player)
      begin
        key = RuneRb::Misc::NameUtils.format_name_protocol(player.name)

        profile = if FileTest.exists?("./data/profiles/#{key}.yaml")
          YAML::load(File.open("./data/profiles/#{key}.yaml"))
        else
          nil
        end

        RuneRb::World::PROFILE_LOG.info "Retrieving profile: #{key}"

        if profile == nil
          default_profile(player)
        else
          player.rights = RuneRb::World::RIGHTS[2] #RuneRb::World::RIGHTS[profile.rights] || :player
          player.members = profile.member
          player.appearance.set_look profile.appearance
          decode_container(player.equipment, profile.equipment)
          decode_container(player.inventory, profile.inventory)
          decode_container(player.bank, profile.bank)
          decode_skills(player.skills, profile.skills)
          player.varp.friends = profile.friends
          player.varp.ignores = profile.ignores
          player.location = RuneRb::Model::Location.new(profile.x, profile.y, profile.z)
          player.settings = profile.settings || {}
        end
      rescue Exception => e
        RuneRb::World::PROFILE_LOG.error "Unable to load profile"
        RuneRb::World::PROFILE_LOG.error e
        return false
      end

      return true
    end

    def save_profile(player)
      key = RuneRb::Misc::NameUtils.format_name_protocol(player.name)

      RuneRb::World::PROFILE_LOG.info "Storing profile: #{key}"

      profile = Profile.new
      profile.hash = player.name_long
      profile.banned = false
      profile.member = player.members
      #profile.rights = RuneRb::World::RIGHTS.index(player.rights)
      profile.x = player.location.x
      profile.y = player.location.y
      profile.z = player.location.z
      profile.appearance = player.appearance.get_look
      profile.skills = encode_skills(player.skills)
      profile.equipment = encode_container(player.equipment)
      profile.inventory = encode_container(player.inventory)
      profile.bank = encode_container(player.bank)
      profile.friends = player.varp.friends
      profile.ignores = player.varp.ignores
      profile.settings = player.settings

      File.open("./data/profiles/#{key}.yaml", "w" ) do |out|
        YAML.dump(profile, out)
        out.flush
      end

      true
    end

    def encode_skills(skills)
      RuneRb::Player::SKILLS.inject([]){|arr, sk|
        arr << [skills.skills[sk], skills.exps[sk]]
      }
    end

    def decode_skills(skills, data)
      data.each_with_index {|val, i|
        skills.set_skill RuneRb::Player::SKILLS[i], val[0], val[1], false
      }
    end

    def encode_container(container)
      arr = Array.new(container.capacity, [-1, -1])

      container.items.each_with_index {|val, i|
        arr[i] = [val.id, val.count] unless val == nil
      }

      arr
    end

    def decode_container(container, arr)
      arr.each_with_index {|val, i|
        container.set i, (val[0] == -1 ? nil : RuneRb::Item::Item.new(val[0], val[1]))
      }
    end

    def default_profile(player)
      player.location = RuneRb::Model::Location.new(3232, 3232, 0)
      player.rights = :admin
    end


    def validate_credentials(username, password)
      true
    end
  end
end
