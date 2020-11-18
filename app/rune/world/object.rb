module RuneRb::World
  # A WorldObjectEvent represents an event pulse event progressing the state of the all WorldObjects maintained by the World Instance
  class WorldObjectEvent < RuneRb::Engine::Event

    # Called when a new WorldObjectEvent is created.
    def initialize(world)
      @world = world
      super(1000)
    end

    # Executes the WorldObjectEvent.
    def execute
      @world.objects.each do |object|
        object.delay -= 1
        next unless object.delay <= 0

        object.reset
        @world.objects.delete(object)
      end
    end
  end

  # A WorldObject models a GameObject that exists in the context of a World Instance.
  class WorldObject
    # @return [Integer] the ID for the WorldObject
    attr_accessor :id

    # @return [RuneRb::Model::Location] the current location of the WorldObject.
    attr_accessor :location

    # @return [Integer] the direction the WorldObject is facing.
    attr_accessor :face

    # @return [Integer] the delay before the object is reset.
    attr_accessor :delay

    # @return [Integer] the type of WorldObject.
    attr :type

    # @return [Integer] the original ID of the WorldObject.
    attr :orig_id

    # @return [RuneRb::Model::Location] the original location of the WorldObject.
    attr :orig_location

    # @return [Integer] the original direction the WorldObject faces.
    attr :orig_face

    # Called when a new WorldObject is created.
    def initialize(world, params = {})
      @world = world
      @id = params[:id]
      @location = params[:location]
      @face = params[:face]
      @type = params[:type]
      @orig_id = params[:orig_id]
      @orig_location = params[:orig_location]
      @orig_face = params[:orig_face]
      @delay = params[:delay]
    end

    # Changes the location and state of the object
    # @param player [RuneRb::Model::Player] the context player
    def change(player = nil)
      puts "Changing or resetting"
      unless player.nil?
        # Remove old object if the new object is in a new location
        if @location != @orig_location
          player.io.send_replace_object(@orig_location, player.last_location, -1, @face, @type)
        end

        # Create the new object for the specific player
        player.io.send_replace_object(@location, player.last_location, @orig_id, @face, @type)
        return
      end

      # Send appropriate frames to local players regarding the state update.
      @world.local_players(@location).each do |plyr|
        plyr.io.send_replace_object(@orig_location, plyr.last_location, -1, @face, @type) if @location != @orig_location
        plyr.io.send_replace_object(@location, plyr.last_location, @id, @face, @type)
      end
    end

    # Alias the function for compatibility
    alias reset change
  end
end