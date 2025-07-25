require 'pathname'
APP_PATH = Pathname.new(File.expand_path("..", __dir__))
require 'bundler/setup'
require 'active_support/all'
require 'tempfile'
require_relative 'lib/init'
