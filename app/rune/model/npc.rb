module RuneRb::NPC
  class NPC < RuneRb::Model::Entity
    attr :definition
    attr_accessor :direction
    
    def initialize(definition, world)
      super(world)
      @definition = definition
    end
    
    def add_to_region(region)
      region.npcs << self
    end
    
    def remove_from_region(region)
      region.npcs.delete self
    end
  end

  class NPCDefinition
    @@definitions = []

    attr :id
    attr_reader :properties

    def initialize(id)
      @id = id
    end

    def NPCDefinition.for_id(id)
      RuneRb::NPC::NPCDefinition.new(id)
    end
  end
end
