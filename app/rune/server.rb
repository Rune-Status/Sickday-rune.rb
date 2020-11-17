module RuneRb
  # A Server object provides a TCP Server instance which accepts and processes incoming socket connections over TCP/IP.
  class Server
    attr :config
    attr_accessor :updatemode
    attr_accessor :max_players

    # Called when a new Server object is created
    def initialize
      @updatemode = false
      @max_players = 1000
      setup_logger
    end

    # Attempts a complicated setup of a logger.
    def setup_logger
      Logging.color_scheme( 'bright',
                            :levels => {
                                :info  => :green,
                                :warn  => :yellow,
                                :error => :red,
                                :fatal => [:white, :on_red]
                            },
                            :date => :white,
                            :logger => :white,
                            :message => :white
      )

      Logging.logger.root.add_appenders(
          Logging.appenders.stdout(
              'stdout',
              :layout => Logging.layouts.pattern(
                  :pattern => '[%d] %-5l %c: %m\n',
                  :color_scheme => 'bright'
              )),
          Logging.appenders.file('data/logs/development.log', :layout => Logging.layouts.pattern(:pattern => '[%d] %-5l %c: %m\n'))
      )

      @log = Logging.logger['server']
    end

    # Attempts to initialize an instance of the server with provided config options
    def start_config(config)
      @config = config
      init_cache
      load_int_hooks
      load_defs
      load_hooks
      load_config
      bind
    end

    # Performs a reloading of plugin files and packet handlers.
    def reload
      HOOKS.clear
      load_hooks
      load_int_hooks
      RuneRb::Net.load_packets
    end

    # Attempts to load all basic plugins.
    def load_hooks
      Dir['./plugins/*.rb'].each { |file| load file }
    end

    # Attempts to load all internal plugins.
    def load_int_hooks
      Dir['./plugins/internal/*.rb'].each { |file| load file }
    end

    # Attempts to initialize a global cache variable which creates a new `RuneRb::Misc::Cache` object accessible by the whole application.
    def init_cache
      $cache = RuneRb::Misc::Cache.new('./data/cache/')
    rescue Exception => e
      $cache = nil
      Logging.logger['cache'].warn e.to_s
    end

    # Attempts to load Item and Equipment definitions from xml files.
    def load_defs
      RuneRb::Item::ItemDefinition.load

      # Equipment
      RuneRb::Equipment.load
    end

    # Attempts to load configuration files and definitions for Doors, Shops, NPCSpawns, and ItemSpawns.
    def load_config
      WORLD.shop_manager.load_shops
      WORLD.door_manager.load_single_doors
      WORLD.door_manager.load_double_doors

      RuneRb::World::NPCSpawns.load
      RuneRb::World::ItemSpawns.load
    end

    # Binds the server socket and begins accepting player connections. Defines Signal traps for `INT` and `TERM` signals to ensure graceful shutdown.
    def bind
      EventMachine.run do
        # Trap certain signals for graceful shut down
        Signal.trap('INT') do
          WORLD.players.each do |p|
            WORLD.unregister(p)
          end

          # Tries to wait for active threads to finish their work.
          sleep(0.01) while WORLD.work_thread.waiting.positive?

          # Kill the reactor Jimmy.
          EventMachine.stop if EventMachine.reactor_running?
          exit
        end

        Signal.trap('TERM') { EventMachine.stop }

        EventMachine.start_server('0.0.0.0', @config.port + 1, RuneRb::Net::JaggrabConnection) if $cache
        EventMachine.start_server('0.0.0.0', @config.port, RuneRb::Net::Connection)
        @log.info "Ready on port #{@config.port}"
      end
    end
  end
end
