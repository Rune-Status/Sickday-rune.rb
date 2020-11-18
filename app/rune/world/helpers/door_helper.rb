# The DoorHelper module provides door handling functionality to the World Instance.
module RuneRb::World::DoorHelper
  # Loads Single door data from the legacy database.
  def load_single_doors
    RuneRb::Database::LEGACY[:door].all.each do |row|
      @single_doors << { id: row[:id],
                         location: RuneRb::Model::Location.new(row[:x],
                                                              row[:y],
                                                              row[:z]),
                         face: row[:face],
                         type: row[:type] }
    end
    puts "Loaded #{@single_doors.size} single doors."
    @single_doors.each do |door|
      handler = HOOKS[:obj_click1][door[:id]]
      next if handler.instance_of?(Proc)

      on_obj_option(door[:id]) do |player, loc|
        next unless player.location.within_interaction_distance?(loc)

        player.walking_queue.reset
        handle_door(door[:id], loc)
      end
    end
  end

  # Loads Double door data from the legacy database.
  def load_double_doors
    RuneRb::Database::LEGACY[:double_door].all.each do |row|
      @double_doors << { id: row[:id],
                         location: RuneRb::Model::Location.new(row[:x],
                                                               row[:y],
                                                               row[:z]),
                         face: row[:face],
                         type: 0 }
    end
    puts "Loaded #{@double_doors.size} double doors."
    @double_doors.each do |door|
      handler = HOOKS[:obj_click1][door[:id]]
      next if handler.instance_of?(Proc)

      on_obj_option(door[:id]) do |player, loc|
        next unless player.location.within_interaction_distance?(loc)

        player.walking_queue.reset
        handle_double_door(door[:id], loc)
      end
    end
  end

  # Handle a single door given it's ID and location
  # @param id [Integer] the ID of the single door
  # @param location [RuneRb::Model::Location] the location of the door
  def handle_door(id, location)
    door = @objects.find { |d| d && d.id == id && d.location == location }

    if !door.nil?
      # Reset cause it's already changed
      door.reset
      @objects.delete(door)
    else
      data = single_door(id, location)
      return if data.nil?

      data[:open] = @open_single_doors.any? { |sdoor| sdoor == id } ? true : false
      # Change door for the first time
      @objects << door = RuneRb::World::Door.new(self, data)

      # Move and rotate
      change_state(door)
      local_players(door.location, false).each do |player|
        player.io.send_replace_object(door.location,
                                      player.last_location,
                                      door.id,
                                      door.face,
                                      door.type)
      end
    end
  end

  # Handles a double door given its ID and location
  # @param id [Integer] the ID for the double door
  # @param location [RuneRb::Model::Location] the location of the door
  def handle_double_door(id, location)
    door = @objects.find do |ddoor|
      ddoor.is_a?(RuneRb::World::DoubleDoor) && (ddoor.id == id && ddoor.location == location || ddoor.r_door_id == id && ddoor.r_door_location == location)
    end

    if !door.nil?
      # Reset cause it's already changed
      door.reset
      @objects.delete(door)
    else
      data = double_door(id, location)
      return if data.nil?

      data[:open] = @open_double_doors.any? { |ddoor| ddoor == id } ? true : false
      # Change door for the first time
      @objects << door = RuneRb::World::DoubleDoor.new(self, data)
    end
  end

  # Changes the state of a door object
  # @param door [RuneRb::World::Door] the door to change
  def change_state(door)
    x_off = 0
    y_off = 0
    face = door.orig_face

    if door.type == 0
      if door.open
        face = (door.face - 1) & 3

        x_off = 1 if door.orig_face == 1
        x_off = -1 if door.orig_face == 3
        y_off = 1 if door.orig_face == 0
        y_off = -1 if door.orig_face == 2
      else
        face = (door.face + 1) & 3

        x_off = 1 if door.orig_face == 2
        x_off = -1 if door.orig_face == 0
        y_off = 1 if door.orig_face == 1
        y_off = -1 if door.orig_face == 3
      end
    elsif door.type == 9
      if door.open
        face = 3 - door.face
      else
        face = (door.face - 1) & 3
      end

      x_off = 1 if door.orig_face == 0 || door.orig_face == 1
      x_off = -1 if door.orig_face == 2 || door.orig_face == 3
    end

    if x_off != 0 || y_off != 0
      local_players(door.location, false).each do |player|
        player.io.send_replace_object(door.location,
                                      player.last_location,
                                      -1, 0,
                                      door.type)
      end
    end

    door.id -= 1 if door.open
    door.id += 1 unless door.open
    door.face = face
    door.location = door.location.transform(x_off, y_off, 0)
  end

  # Change the state of a double door object
  # @param door [RuneRb::World::DoubleDoor] the DoubleDoor to change the state for
  def change_double_state(door)
    # Left
    x_off = 0
    y_off = 0
    face = door.orig_face

    if door.open
      face = 1 + door.face % 2

      x_off = -1 if door.orig_face == 1 || door.orig_face == 2 || door.orig_face == 3
      y_off = -1 if door.orig_face == 0
    else
      face = 2 * (-door.face / 3.floor + 1) + (door.face - 1) % 2

      x_off = 1 if door.orig_face == 2
      x_off = -1 if door.orig_face == 0
      y_off = 1 if door.orig_face == 1
      y_off = -1 if door.orig_face == 3
    end

    if x_off != 0 || y_off != 0
      local_players(door.location, false).each do |player|
        player.io.send_replace_object(door.location,
                                      player.last_location,
                                      -1, 0, 0)
      end
    end

    door.id -= 1 if door.open
    door.id += 1 unless door.open
    door.face = face
    door.location = door.location.transform x_off, y_off, 0

    unless door.id.nil?
      local_players(door.location, false).each do |player|
        player.io.send_replace_object(door.location,
                                      player.last_location,
                                      door.id,
                                      door.face, 0)
      end
    end

    # Right
    x_off = 0
    y_off = 0
    face = door.r_door_orig_face

    if door.open
      face = 3 if door.r_door_orig_face == 0
      face = 0 if door.r_door_orig_face == 1
      face = 1 if door.r_door_orig_face == 2
      face = 2 if door.r_door_orig_face == 3

      x_off = 1 if door.r_door_orig_face == 0
      x_off = -1 if door.r_door_orig_face == 1 || door.r_door_orig_face == 3
      y_off = -1 if door.r_door_orig_face == 2
    else
      face = 1 if door.r_door_orig_face == 0
      face = 2 if door.r_door_orig_face == 1
      face = 3 if door.r_door_orig_face == 2
      face = 2 if door.r_door_orig_face == 3

      x_off = 1 if door.r_door_orig_face == 2
      x_off = -1 if door.r_door_orig_face == 0
      y_off = 1 if door.r_door_orig_face == 1
      y_off = -1 if door.r_door_orig_face == 3
    end

    if x_off != 0 || y_off != 0

      local_players(door.r_door_location, false).each do |player|
        player.io.send_replace_object(door.r_door_location,
                                      player.last_location,
                                      -1, 0, 0)
      end
    end

    door.r_door_id -= 1 if door.open
    door.r_door_id += 1 unless door.open
    door.r_door_face = face
    door.r_door_location = door.r_door_location.transform(x_off, y_off, 0)
    return if door.r_door_id.nil?

    local_players(door.location, false).each do |player|
      player.io.send_replace_object(door.r_door_location,
                                    player.last_location,
                                    door.r_door_id,
                                    door.r_door_face,
                                    0)
    end
  end

  # Retrieves a single door with the given ID and location
  # @param id [Integer] the id of the Door
  # @param location [RuneRb::Model::Location] the location of the Door
  def single_door(id, location)
    @single_doors.detect do |door|
      door[:id] == id && door[:location] == location
    end
  end

  # Retrieves the double door with the given ID and location
  # @param id [Integer] the id of the DoubleDoor
  # @param location [RuneRb::Model::Location] the location of the DoubleDoor
  def double_door(id, location)
    @double_doors.detect do |door|
      door[:id] == id && door[:location] == location
    end
  end
end