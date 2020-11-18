module RuneRb::World
  # A object model of a Door object.
  class Door < RuneRb::World::WorldObject
    # @return [Boolean] is the door opened?
    attr :open

    # Called when a new Door is created.
    def initialize(world, params = { open: true })
      @open = params[:open]
      super(world, id: params[:id],
            location: params[:location],
            face: params[:face],
            type: params[:type],
            orig_id: params[:id],
            orig_location: params[:location],
            orig_face: params[:face],
            delay: 300)
    end
  end

  # A object model of a DoubleDoor object.
  class DoubleDoor < Door
    # @@return [Integer] the id for the door.
    attr :id

    # @return [Integer] the right door ID
    attr_accessor :r_door_id

    # @return [RuneRb::Model::Location] the location of the right door
    attr_accessor :r_door_location

    # @return [Integer] the direction the right door is facing
    attr_accessor :r_door_face

    # @return [Integer] the right door's original ID
    attr :r_door_orig_id

    # @return [RuneRb::Model::Location] the original location of the right door.
    attr :r_door_orig_location

    # @return [Integer] the right door's original facing direction
    attr :r_door_orig_face

    # Called when a new DoubleDoor object is created
    def initialize(world, params = { open: true })
      super(world, params)

      l_id_off = -3
      r_id_off = 3
      l_x_off = 0
      r_x_off = 0
      l_y_off = 0
      r_y_off = 0

      if open
        if params[:face] == 0
          l_x_off = -1
          r_x_off = 1
        elsif params[:face] == 1
          l_y_off = 1
          r_y_off = -1
        elsif params[:face] == 2
          l_x_off = -1
          r_y_off = -1
        elsif params[:face] == 3
          l_y_off = 1
          r_y_off = -1
        end
      else
        if params[:face] == 0
          l_y_off = -1
          r_y_off = 1
        elsif params[:face] == 1
          l_x_off = -1
          r_x_off = 1
        elsif params[:face] == 2
          l_y_off = 1
          r_y_off = -1
        elsif params[:face] == 3
          l_id_off = 3
          r_id_off = -3
          l_x_off = -1
          r_x_off = 1
        end
      end

      temp_l = RuneRb::Model::Location.new(params[:location].x + l_x_off,
                                           params[:location].y + l_y_off,
                                           params[:location].z)
      temp_r = RuneRb::Model::Location.new(params[:location].x + r_x_off,
                                           params[:location].y + r_y_off,
                                           params[:location].z)

      l_data = @world.double_door((params[:id] + l_id_off), temp_l)
      r_data = @world.double_door((params[:id] + r_id_off), temp_r)

      unless l_data.nil?
        @id = l_data[:id]
        @location = l_data[:location]
        @face = l_data[:face]

        @orig_id = @id
        @orig_location = RuneRb::Model::Location.new(@location.x,
                                                     @location.y,
                                                     @location.z)
        @orig_face = @face

        # HACKS
        @r_door_id = params[:id]
        @r_door_location = params[:location]
        @r_door_face = params[:face]

        @r_door_orig_id = @r_door_id
        @r_door_orig_location = RuneRb::Model::Location.new(@r_door_location.x,
                                                            @r_door_location.y,
                                                            @r_door_location.z)
        @r_door_orig_face = @r_door_face

        @world.change_double_state(self)
      end

      return if r_data.nil?

      # HACKS
      @id = params[:id]
      @location = params[:location]
      @face = params[:face]

      @orig_id = @id
      @orig_location = RuneRb::Model::Location.new(@location.x,
                                                   @location.y,
                                                   @location.z)
      @orig_face = @face

      @r_door_id = r_data[:id]
      @r_door_location = r_data[:location]
      @r_door_face = r_data[:face]

      @r_door_orig_id = @r_door_id
      @r_door_orig_location = RuneRb::Model::Location.new(@r_door_location.x,
                                                          @r_door_location.y,
                                                          @r_door_location.z)
      @r_door_orig_face = @r_door_face

      @world.change_double_state(self)
    end

    # Change the DoubleDoor's state in the context of a player
    # @param player [RuneRb::Model::Player] the context player.
    def change(player)
      return if player.nil?

      # Delete if the new door has moved
      if @location != @orig_location
        player.io.send_replace_object(@orig_location, player.last_location, -1, 0, 0)
        player.io.send_replace_object(@r_door_orig_location, player.last_location, -1, 0, 0)
      end

      player.io.send_replace_object(@location, player.last_location, @id, @face, 0)

      player.io.send_replace_object(@r_door_location, player.last_location, @r_door_id, @r_door_face, 0)
    end

    # Resets the state of the DoubleDoor object.
    def reset
      if @location != @orig_location
        # Remove the old replaced doors if they moved
        @world.local_players(@location, false).each do |player|
          player.io.send_replace_object(@location,
                                        player.last_location,
                                        -1, 0, 0)
          player.io.send_replace_object(@r_door_location,
                                        player.last_location,
                                        -1, 0, 0)
        end
      end

      # Reset ids/positions/rotations
      @id = @orig_id
      @r_door_id = @r_door_orig_id
      @location = @orig_location
      @r_door_location = @r_door_orig_location
      @face = @orig_face
      @r_door_face = @r_door_orig_face

      # Add back to original locations
      @world.local_players(@location, false).each do |player|
        player.io.send_replace_object(@location,
                                      player.last_location,
                                      @id,
                                      @face, 0)
        player.io.send_replace_object(@r_door_location,
                                      player.last_location,
                                      @r_door_id,
                                      @r_door_face, 0)
      end
    end
  end

end