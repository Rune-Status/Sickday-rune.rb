module RuneRb::Player::Constants
  MAX_EXP = 200_000_000
  SKILLS = %i[
    attack
    defence
    strength
    hitpoints
    range
    prayer
    magic
    cooking
    woodcutting
    fletching
    fishing
    firemaking
    crafting
    smithing
    mining
    herblore
    agility
    thieving
    slayer
    farming
    runecrafting
  ].freeze
  REQUESTS = { trade: 'tradereq', duel: 'duelreq' }.freeze
end