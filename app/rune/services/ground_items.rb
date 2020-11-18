module RuneRb::GroundItems
  class GroundItem
    attr :item
    attr :location
    attr :player
    attr :region
    attr :life
    attr :global
    attr :available
    attr :on_table

    def initialize(player, item, on_table = false)
      @item = item
      @player = player
      @region = @player.region
      @location = @player.location
      @available = true
      @global = false
      @life = RuneRb::GroundItems::GroundItemEvent.new self
      @on_table = on_table
      @region.ground_items << self
    end

    def make_global
      @global = true

      WORLD.local_players(@location).each do |player|
        player.io.send_grounditem_creation(self) unless player.eql?(@player)
      end
    end

    def remove
      return unless @available

      @available = false
      @life.stop
      @region.ground_items.delete(self)

      if @global
        WORLD.local_players(@location).each do |player|
          player.io.send_grounditem_removal(self)
        end
      else
        @player.io.send_grounditem_removal self
      end
    end
  end

  class GroundItemEvent < RuneRb::Engine::Event
    attr :item

    def initialize(item)
      super(30_000)
      @item = item
    end

    def execute
      if !@item.global
        if @item.available
          @item.make_global
        else
          stop
        end
      else
        @item.remove if @item.available
        stop
      end
    end
  end

  class PickupItemAction < RuneRb::Engine::Action
    attr :item

    def initialize(player, item)
      super(player, item.on_table ? 900 : 50)
      @item = item
    end

    def execute
      puts "Picking up #{item}"
      p_loc = @player.location
      item_loc = @item.location

      if !@item.available
        @player.walking_queue.reset
        stop
      elsif (@item.on_table && p_loc.within_interaction_distance?(item_loc)) || (p_loc.x == item_loc.x && p_loc.y == item_loc.y)
        if @player.inventory.has_room_for @item.item

          @player.inventory.add @item.item
          @item.remove
        else
          @player.io.send_message('You do not have enough room for that!')
        end
      end

      stop
    end

    def queue_policy
      RuneRb::Engine::QueuePolicy::NEVER
    end

    def walkable_policy
      RuneRb::Engine::WalkablePolicy::WALKABLE
    end
  end
end
