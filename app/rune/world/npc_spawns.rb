module RuneRb::World
  class NPCSpawns

    def NPCSpawns.load

      npc = XmlSimple.xml_in("data/npc_spawns.xml")
      npc["npc"].each_with_index {|row, idx|
        NPCSpawns.spawn(row)
      }
    end


  end
end