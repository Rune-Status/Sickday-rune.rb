module RuneRb::World
  # A WorldItemEvent is an event executing in the context of a Item belonging to the World instance
  class WorldItemEvent < RuneRb::Engine::Event
    # Called when a new WorldItemEvent is created
    # @param world [RuneRb::World::World] the world in which the event will execute.
    def initialize(world)
      @world = world
      super(1000)
    end

    # Executes the World Item event.
    def execute
      @world.items.each do |item|
        item.respawn -= 1 if item.picked_up
        item.spawn if item.picked_up && item.respawn <= 0
      end
    end
  end

  # A WorldItem is an item that exists in the context of a World Instance
  class WorldItem
    # @return [Integer] the time until the WorldItem respawns
    attr_accessor :respawn

    # @return [RuneRb::Item::Item] the actual Item
    attr :item

    # @return [RuneRb::Model::Location] the location of the WorldItem in the World instance
    attr :location

    # @return [Integer] the original delay before the WorldItem would respawn
    attr :orig_respawn

    # @return [Boolean] is the WorldItem picked up?
    attr :picked_up

    # @return [Boolean] is the WorldItem on a table?
    attr :on_table

    # Called when a new WorldItem is created
    # @param world [RuneRb::World::World] the world the item exists in
    # @param data [Hash] the data for the world item
    def initialize(world, data)
      @world = world
      @item = RuneRb::Item::Item.new(data[:id], 1)
      @location = RuneRb::Model::Location.new(data[:x], data[:y], data[:z])
      @respawn = data[:respawn] || 300 # Number of seconds before it will respawn
      @orig_respawn = @respawn
      @picked_up = false
      @on_table = data[:table]
    rescue StandardError => e
      puts "An error occurred initializing WorldItem: #{data.inspect}"
      puts e
      puts e.backtrace
    end

    # Is the WorldItem within distance of a player?
    # @param player [RuneRb::Model::Player] the player to check the distance
    def within_distance?(player)
      player.location.within_distance?(@location)
    end

    # Is the World item available to be picked up?
    def available
      true
    end

    # Spawn an item in the context of a player (and surrounding players)
    # @param player [RuneRb::Model::Player] the player to spawn the WorldItem for
    def spawn(player = nil)
      @picked_up = false
      @respawn = @orig_respawn
      unless player.nil?
        player.io.send_grounditem_creation(self)
        return
      end

      @world.local_players(@location).each do |mob|
        mob.io.send_grounditem_creation(self)
      end
    end

    # Remove the world item in the context of players around it
    def remove
      @picked_up = true
      @world.local_players(@location).each do |player|
        player.io.send_grounditem_removal(self)
      end
    end
  end
end