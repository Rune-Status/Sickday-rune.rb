require 'logging'
require 'eventmachine'
require 'sequel'
require 'socket'
require 'sqlite3'
require 'rufus/scheduler'
require 'ostruct'
require 'yaml'
require 'shellwords'
require 'xmlsimple'
require 'oj'
require 'pp'
require 'pry'
require 'to_regexp'

# Top-Level namespace
# Rune.rb is a game server written in Ruby targeting the 2006 era of RuneScape (or the 317-377 protocols). This branch is a fork of the first known ruby server, calyx.
module RuneRb
  # An object providing a TCP Server instance via EventMachine.
  autoload :Server,             'rune/server'

  # The Engine module is responsible for scheduling, executing, and observing Events and Actions.
  module Engine
    autoload :EventManager,     'rune/core/engine'
    autoload :Event,            'rune/core/engine'
    autoload :QueuePolicy,      'rune/core/engine'
    autoload :WalkablePolicy,   'rune/core/engine'
    autoload :Action,           'rune/core/engine' # TODO move to Actions
    autoload :ActionQueue,      'rune/core/engine' # TODO move to Actions
  end

  # The Misc module provides Miscellaneous reusable functions to the application.
  module Misc
    autoload :AutoHash,            'rune/core/util'
    autoload :HashWrapper,         'rune/core/util'
    autoload :Flags,               'rune/core/util'
    autoload :TextUtils,           'rune/core/util'
    autoload :NameUtils,           'rune/core/util'
    autoload :ThreadPool,          'rune/core/util'
    autoload :Cache,               'rune/core/cache'
  end

  # The Actions module contains various types of Actions.
  module Actions
    autoload :HarvestingAction,    'rune/core/actions'
  end

  # The Model module provides object models of abstract types.
  module Model
    require_relative 'rune/model/constants'
    include Constants

    autoload :HitType,             'rune/model/combat'
    autoload :Hit,                 'rune/model/combat'
    autoload :Damage,              'rune/model/combat'
    autoload :Animation,           'rune/model/effects'
    autoload :Graphic,             'rune/model/effects'
    autoload :ChatMessage,         'rune/model/effects'
    autoload :Entity,              'rune/model/entity'
    autoload :Location,            'rune/model/location'
    autoload :Player,              'rune/model/player'
    autoload :RegionManager,       'rune/model/region'
    autoload :Region,              'rune/model/region'
  end

  # The Item module provides Item-related object models.
  module Item
    autoload :Item,                       'rune/model/item'
    autoload :ItemDefinition,             'rune/model/item'
    autoload :Container,                  'rune/model/item'
    autoload :ContainerListener,          'rune/model/item'
    autoload :InterfaceContainerListener, 'rune/model/item'
    autoload :WeightListener,             'rune/model/item'
    autoload :BonusListener,              'rune/model/item'
  end

  # The NPC module provides NPC-specific objects, models, and modules.
  module NPC
    autoload :NPC,                 'rune/model/npc'
    autoload :NPCDefinition,       'rune/model/npc'
  end

  # The Player module provides Player-specific objects, models, and modules.
  module Player
    require_relative 'rune/model/player/constants'
    include Constants

    autoload :Appearance,          'rune/model/player/appearance'
    autoload :InterfaceState,      'rune/model/player/interfacestate'
    autoload :RequestManager,      'rune/model/player/requestmanager'
    autoload :Skills,              'rune/model/player/skills'
  end

  # The Net module provides most Network-base functionality.
  module Net
    autoload :ActionSender,        'rune/net/actionsender'
    autoload :ISAAC,               'rune/net/isaac'
    autoload :Session,             'rune/net/session'
    autoload :Connection,          'rune/net/connection'
    autoload :Packet,              'rune/net/packet'
    autoload :PacketBuilder,       'rune/net/packetbuilder'
    autoload :JaggrabConnection,   'rune/net/jaggrab'
  end

  # The GroundItems module provides functions and models for managing ground items.
  module GroundItems
    autoload :GroundItem,          'rune/services/ground_items'
    autoload :GroundItemEvent,     'rune/services/ground_items'
    autoload :PickupItemAction,    'rune/services/ground_items'
  end

  module Shops
    autoload :ShopManager,         'rune/services/shops'
    autoload :Shop,                'rune/services/shops'
  end

  module Objects
    autoload :ObjectManager,       'rune/services/objects'
  end

  module Doors
    autoload :DoorManager,         'rune/services/doors'
    autoload :Door,                'rune/services/doors'
    autoload :DoubleDoor,          'rune/services/doors'
    autoload :DoorEvent,           'rune/services/doors'
  end

  # The Tasks module provides Task objects and Events used by the game world.
  module Tasks
    autoload :NPCTickTask,         'rune/tasks/npc_update'
    autoload :NPCResetTask,        'rune/tasks/npc_update'
    autoload :NPCUpdateTask,       'rune/tasks/npc_update'
    autoload :PlayerTickTask,      'rune/tasks/player_update'
    autoload :PlayerResetTask,     'rune/tasks/player_update'
    autoload :PlayerUpdateTask,    'rune/tasks/player_update'
    autoload :SystemUpdateEvent,   'rune/tasks/sysupdate_event'
    autoload :UpdateEvent,         'rune/tasks/update_event'
  end

  # The World module provides models for objects used by the game world.
  module World
    require_relative 'rune/world/constants'
    include Constants

    autoload :Profile,             'rune/world/profile'
    autoload :Pathfinder,          'rune/world/walking'
    autoload :Point,               'rune/world/walking'
    autoload :Item,                'rune/world/item_spawns'
    autoload :World,               'rune/world/world'
    autoload :LoginResult,         'rune/world/world'
    autoload :Loader,              'rune/world/world'
    autoload :YAMLFileLoader,      'rune/world/world'
    autoload :NPCSpawns,           'rune/world/npc_spawns'
    autoload :ItemSpawns,          'rune/world/item_spawns'
  end

  # The Database module provides database connectivity and models
  module Database
    require_relative 'rune/db/connection'
    include Connection

  end
end

require 'rune/plugin_hooks'
require 'rune/net/packetloader'

