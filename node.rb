$:.unshift File.join(File.dirname(__FILE__), "app")

require 'bundler/setup'
require 'rune'

WORLD = RuneRb::World::World.new
SERVER = RuneRb::Server.new
SERVER.start_config(RuneRb::Misc::HashWrapper.new({port: 43_594}))

