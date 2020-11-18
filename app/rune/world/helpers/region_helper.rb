# A RegionHelper module provides region management functionality
# Manages all active regions within a World instance
module RuneRb::World::RegionHelper
  # Returns a collection of players local to a location. If distance is passed, distance will determine what players are returned in the collection.
  # @param reference [RuneRb::Model::Location, RuneRb::Model::Player] the reference point to get local players for
  # @param distance [Boolean] determines if we should check interaction distance for players to add.
  def local_players(reference, distance = true)
    location = reference.is_a?(RuneRb::Model::Location) ? reference : reference.location
    surrounding_regions(location).each_with_object([]) do |region, players|
      if distance
        region.players.each do |player|
          players << player if player.location.within_distance?(location)
        end
      else
        region.players.each { |player| players << player }
      end
    end
  end

  # Returns a collection of local mobs relative to the provided mob
  # @param mob [RuneRb::Model::Entity] the mob to get local mobs for
  def local_mobs(mob)
    surrounding_regions(mob.location).each_with_object([]) do |region, mobs|
      region.mobs.each do |r_mob|
        mobs << r_mob if r_mob.location.within_distance?(mob.location)
      end
    end
  end

  # Returns the region for the given coordinates
  # @param x [Integer] the x coordinate
  # @param y [Integer] the y coordinate
  def region_for_coordinates(x, y)
    region = @regions.detect { |rg| rg.x == x and rg.y == y }
    return region unless region.nil?

    @regions << region = RuneRb::Model::Region.new(x, y)
    region
  end

  # Returns the region for the given location
  # @param location [RuneRb::Model::Location] the location to retrieve the region for.
  def region_for_location(location)
    region_for_coordinates(location.x / RuneRb::Model::REGION_SIZE,
                           location.y / RuneRb::Model::REGION_SIZE)
  end

  # Returns a collection of regions surrounding the location.
  # @param location [RuneRb::Model::Location] the location to retrieve surrounding regions for.
  def surrounding_regions(location)
    regions = []
    (-2..2).each do |pos_x|
      (-2..2).each do |pos_y|
        regions << region_for_coordinates((location.x / RuneRb::Model::REGION_SIZE) + pos_x,
                                          (location.y / RuneRb::Model::REGION_SIZE) + pos_y)
      end
    end
    regions
  end
end