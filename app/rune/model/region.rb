module RuneRb::Model
  # Manage all active regions within the server
  class RegionManager
    attr :active_regions

    def initialize
      @active_regions = []
    end

    def get_local_players(ref, check_distance = true)
      loc = ref.is_a?(Location) ? ref : ref.location

      get_surrounding_regions(loc).each_with_object([]) do |region, players|
        if check_distance
          region.players.each do |player|
            players << player if player.location.within_distance?(loc)
          end
        else
          region.players.each { |player| players << player }
        end
      end
    end

    def get_local_npcs(entity)
      get_surrounding_regions(entity.location).each_with_object([]) do |region, npcs|
        region.npcs.each do |n|
          npcs << n if n.location.within_distance?(entity.location)
        end
      end
    end

    def get_surrounding_regions(location)
      regions = []
      (-2..2).each {|x|
        (-2..2).each {|y|
          regions << get_region((location.x / 32)+x, (location.y / 32)+y)
        }
      }

      regions
    end

    def get_region(x, y)
      region = @active_regions.find {|region| region.x == x and region.y == y }

      if region == nil
        region = Region.new x, y
        @active_regions << region
      end

      region
    end

    def get_region_for_location(location)
      get_region location.x / RuneRb::Model::REGION_SIZE, location.y / RuneRb::Model::REGION_SIZE
    end
  end

  # A section of the world
  class Region
    attr :x
    attr :y
    attr_reader :players
    attr :npcs
    attr :ground_items

    def initialize(x, y)
      @x = x
      @y = y
      @players = []
      @npcs = []
      @ground_items = []
    end

    def ==(other)
      return unless other.instance_of? self.class

      @x == other.x and @y == other.y
    end
  end
end
