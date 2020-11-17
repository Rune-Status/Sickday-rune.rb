module RuneRb::Model::Constants
  REGION_SIZE = 32
  ITEM_PROPERTIES = %i[name noted parent noteable noteID stackable members prices basevalue att_stab_bonus
                att_slash_bonus att_crush_bonus att_magic_bonus att_ranged_bonus def_stab_bonus def_slash_bonus
                def_crush_bonus def_magic_bonus def_ranged_bonus strength_bonus prayer_bonus weight].freeze
  ITEM_BOOLS = %i[noted noteable stackable members prices].freeze
  MAX_ITEMS = 2**31 - 1
end