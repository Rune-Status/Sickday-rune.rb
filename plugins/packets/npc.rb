# NPC attack
on_packet(72) {|player, packet|
  npc_slot = packet.read_short_a.ushort
  npc = WORLD.npcs[npc_slot-1]
  
  next unless player.location.within_interaction_distance?(npc.location)

  handler = HOOKS[:npc_attack][npc.definition.id]
      
  if handler.instance_of?(Proc)
    handler.call(player, npc)
  end
}

# NPC option 1
on_packet(155) {|player, packet|
  npc_slot = packet.read_leshort.ushort
  npc = WORLD.npcs[npc_slot-1]
  
  next unless player.location.within_interaction_distance?(npc.location)
  
  handler = HOOKS[:npc_option1][npc.definition.id]
  
  if handler.instance_of?(Proc)
    handler.call(player, npc)
  end
}

# NPC option 2
on_packet(17) do |player, packet|
  npc_slot = packet.read_leshort_a.ushort
  npc = WORLD.npcs[npc_slot-1]
  
  next unless player.location.within_interaction_distance?(npc.location)
  
  handler = HOOKS[:npc_option2][npc.definition.id]
      
  if handler.instance_of?(Proc)
    handler.call(player, npc)
  end
end

# NPC option 3
# TODO: This is broken because the NPC_Slot is a number unknown to the world. Its far larger than the actual index of the npc.
on_packet(21) do |player, packet|
=begin
  npc_slot = packet.read_leshort_a.ushort
  puts "SLot #{npc_slot}"
  npc = WORLD.npcs[npc_slot-1]
  next unless player.location.within_interaction_distance?(npc&.location)

  HOOKS[:npc_option3][npc.definition.id]&.call(player, npc) if handler.instance_of?(Proc)
=end
end
