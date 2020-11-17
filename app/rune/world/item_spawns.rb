module RuneRb::World

  class ItemEvent < RuneRb::Engine::Event
    def initialize
      super(1000)
    end

    def execute
      WORLD.items.each do |item|
        item.respawn -= 1 if item.picked_up
        item.spawn if item.picked_up && item.respawn <= 0
      end
    end
  end

  class Item
    attr :item
    attr :location
    attr_accessor :respawn
    attr :orig_respawn
    attr :picked_up
    attr :on_table

    def initialize(data)
      @item = RuneRb::Item::Item.new(data[:id], data[:amount] || 1)
      @location = RuneRb::Model::Location.new(data[:x], data[:y], data[:z])
      @respawn = data[:respawn] || 300 # Number of seconds before it will respawn
      @orig_respawn = @respawn
      @picked_up = false
      @on_table = data[:table]
    end

    def remove
      @picked_up = true

      WORLD.region_manager.get_local_players(@location).each do |player|
        player.io.send_grounditem_removal(self)
      end
    end

    def spawn(player = nil)
      @picked_up = false
      @respawn = @orig_respawn

      unless player.nil?
        player.io.send_grounditem_creation(self)
        return
      end

      WORLD.region_manager.get_local_players(@location).each do |p|
        p.io.send_grounditem_creation(self)
      end
    end

    def within_distance?(player)
      player.location.within_distance? @location
    end

    def available
      true
    end
  end
end
