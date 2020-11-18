module RuneRb::Model
  # A section of the world
  class Region
    # @return [Integer] the x coordinate of the region.
    attr :x

    # @return [Integer] the y coordinate of the region.
    attr :y

    # @return [Array] the players within the region.
    attr :players

    # @return [Array] the mobs within the region.
    attr :npcs

    # @return [Array] the mobs within the region.
    attr :mobs

    # the ground items for the region
    attr :ground_items

    # Called when a new Region is created
    # @param x [Integer] the x coordinate of the region
    # @param y [Integer] the y coordinate of the region
    def initialize(x, y)
      @x = x
      @y = y
      @players = []
      @npcs = []
      @mobs = []
      @ground_items = []
    end

    # Checks if the region contains the same coordinates as the compared
    # @param other [Region] the other region to compare to.
    def ==(other)
      return unless other.instance_of? self.class

      @x == other.x and @y == other.y
    end
  end
end
