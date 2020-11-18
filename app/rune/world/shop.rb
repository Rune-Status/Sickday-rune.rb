module RuneRb::World
  class Shop
    attr :container
    attr_accessor :name
    attr_accessor :generalstore
    attr_accessor :customstock
    attr_accessor :original_stock

    def initialize
      @container = RuneRb::Item::Container.new true, 40
    end

    def original_stock=(stock)
      @container.clear
      @original_stock = stock
      @original_stock.each do |item, amount|
        @container.items << RuneRb::Item::Item.new(item, amount)
      end
    end
  end
end