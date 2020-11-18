module RuneRb::World
  # A World object models a virtual game world.
  class World
    include RuneRb::World::RegionHelper
    include RuneRb::World::DoorHelper

    # @return [Array] a collection of players handled by the World Instance.
    attr :players

    # @return [Array] a collection of npcs handled by the World Instance.
    attr :npcs

    # @return [Array] a collection of items handled by the World Instance.
    attr :items

    # @return [Array] a collection of objects handled by the World Instance.
    attr :objects

    # @return [Hash] a map of shops handled by the World Instance.
    attr :shops

    attr :event_manager
    attr :shop_manager
    #attr :door_manager
    #attr :object_manager
    attr :loader
    attr :work_thread

    # Called when a new World Instance is created.
    def initialize
      @players = []
      @npcs = []
      @items = []
      @shops = {}
      @regions = []
      @objects = []

      # Door Handling
      @single_doors = []
      @double_doors = []
      @open_single_doors = [ 1504, 1514, 1517, 1520, 1531,
                             1534, 2033, 2035, 2037, 2998,
                             3271, 4468, 4697, 6101, 6103,
                             6105, 6107, 6109, 6111, 6113,
                             6115, 6976, 6978, 8696, 8819,
                             10_261, 10_263, 10_265, 11_708, 11_710,
                             11_712, 11_715, 11_994, 12_445, 13_002]
      @open_double_doors = [1520, 1517]

      @event_manager = RuneRb::Engine::EventManager.new
      @loader = YAMLFileLoader.new
      @task_thread = RuneRb::Misc::ThreadPool.new(1)
      @work_thread = RuneRb::Misc::ThreadPool.new(1)
      @shop_manager = RuneRb::Shops::ShopManager.new
      #@object_manager = RuneRb::Objects::ObjectManager.new
      #@door_manager = RuneRb::Doors::DoorManager.new

      load_item_spawns
      load_shops
      load_doors
      load_mob_spawns
      register_global_events
    end

    # Loads item spawns from the database and creates appropriate WorldItems for models.
    def load_item_spawns
      RuneRb::Database::LEGACY[:item_spawns].all.each do |item|
        @items << RuneRb::World::WorldItem.new(self, item)
      end
      submit_event(RuneRb::World::WorldItemEvent.new(self))
    rescue StandardError => e
      puts 'An error occurred while spawning Items!'
      puts e
      puts e.backtrace
    end

    # Loads mob spawns from the database and creates appropriate Mobs for models.
    def load_mob_spawns
      RuneRb::Database::LEGACY[:mob_spawns].all.each do |row|
        spawn_mob(row, row[:shop_id] || nil)
      end
    rescue StandardError => e
      puts 'An error occurred while spawning Mobs!'
      puts e
      puts e.backtrace
    end

    # Loads shop data from the database and parses shops from that data.
    def load_shops
      RuneRb::Database::LEGACY[:shops].all.each do |shop_data|
        @shops[shop_data[:id]] = RuneRb::Shops::Shop.new
        @shops[shop_data[:id]].name = shop_data[:name]
        @shops[shop_data[:id]].generalstore = shop_data[:general_store]
        @shops[shop_data[:id]].customstock = true
        @shops[shop_data[:id]].original_stock = {}.tap do |hash|
          parsed = Oj.load(shop_data[:inventory].gsub('=>', ':'))
          parsed.each do |item|
            hash[item['id'].to_i] = item['amount'].to_i
          end
        end
      end
    rescue StandardError => e
      puts 'An error occurred while loading Shops!'
      puts e
      puts e.backtrace
    end

    # Calls door loading functions on the `World#door_manager`
    def load_doors
      load_single_doors
      load_double_doors
    rescue StandardError => e
      puts 'An error occurred while loading Doors!'
      puts e
      puts e.backtrace
    end

    def add_to_login_queue(session)
      submit_work do
        lr = @loader.check_login(session)
        response = lr.response

        # New login, so try loading profile
        response = 13 if response == 2 && !@loader.load_profile(lr.player)

        if response == 2
          session.player = lr.player
          submit_task do
            register lr.player
          end
        else
          bldr = RuneRb::Net::PacketBuilder.new(-1, :RAW)
          bldr.add_byte response
          session.connection.send_data bldr.to_packet
          session.connection.close_connection true
        end
      end
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

      HOOKS[:player_login].each do |k, v|
        begin
          v.call(player)
        rescue Exception => e
          RuneRb::World::PLUGIN_LOG.error "Unable to run login hook #{k}"
          RuneRb::World::PLUGIN_LOG.error e
        end
      end

      player.io.send_login
    end

    def unregister(player, single=true)
      if @players.include?(player)
        HOOKS[:player_logout].each do |k, v|
          begin
            v.call(player)
          rescue Exception => e
            RuneRb::World::PLUGIN_LOG.error "Unable to run logout hook #{k}"
            RuneRb::World::PLUGIN_LOG.error e
          end
        end

        player.destroy
        player.connection.close_connection_after_writing
        @players.delete(player) if single
        submit_work do
          @loader.save_profile(player)
        end
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

    def spawn_mob(data, shop = nil)
      npc = RuneRb::NPC::NPC.new(RuneRb::NPC::NPCDefinition.for_id(data[:mob_id]), self)
      npc.location = RuneRb::Model::Location.new(data[:x], data[:y], data[:z])
      npc.direction = data[:face]&.to_sym || :north
      case data[:face]
      when 'north_west' then npc.direction = :northwest
      when 'north_east' then npc.direction = :northeast
      when 'south_east' then npc.direction = :southeast
      when 'south_west' then npc.direction = :southwest
      end
      offsets = RuneRb::World::NPC_DIRECTIONS[npc.direction]
      npc.face(npc.location.transform(offsets[0], offsets[1], 0))
      register_npc(npc)
      # Add shop hook if NPC owns a shop
      return unless shop && !HOOKS[:npc_option2][data[:mob_id]].is_a?(Proc)

      on_npc_option2(data[:mob_id]) do |player, npc|
        WORLD.shop_manager.open(data[:shop_id], player)
        player.interacting_entity = npc
      end
    end

    private

    def register_global_events
      submit_event RuneRb::Tasks::UpdateEvent.new
      submit_event RuneRb::World::WorldObjectEvent.new(self)
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
      raise 'check_login not implemented'
    end

    def load_profile(player)
      raise 'load_profile not implemented'
    end

    def save_profile(player)
      raise 'save_profile not implemented'
    end
  end

  class YAMLFileLoader < Loader
    def check_login(session)
      # Check password validity
      return LoginResult.new(3, nil) unless validate_credentials(session.username, session.password)

      existing = WORLD.players.find(nil) {|p| p.name.eql?(session.username)}

      if existing.nil?
        # no existing user with this name, new login
        return LoginResult.new(2, RuneRb::Model::Player.new(session, WORLD))
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

        if profile.nil?
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
        RuneRb::World::PROFILE_LOG.error 'Unable to load profile'
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

      File.open("./data/profiles/#{key}.yaml", 'w' ) do |out|
        YAML.dump(profile, out)
        out.flush
      end

      true
    end

    def encode_skills(skills)
      RuneRb::Player::SKILLS.inject([]) do |arr, sk|
        arr << [skills.skills[sk], skills.exps[sk]]
      end
    end

    def decode_skills(skills, data)
      data.each_with_index do |val, i|
        skills.set_skill RuneRb::Player::SKILLS[i], val[0], val[1], false
      end
    end

    def encode_container(container)
      arr = Array.new(container.capacity, [-1, -1])

      container.items.each_with_index do |val, i|
        arr[i] = [val.id, val.count] unless val.nil?
      end

      arr
    end

    def decode_container(container, arr)
      arr.each_with_index do |val, i|
        container.set i, (val[0] == -1 ? nil : RuneRb::Item::Item.new(val[0], val[1]))
      end
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
