require_relative 'dsl'
require_relative 'vault'

def load_config(file='config/vault.rb')
  file = Pathname.new(file)
  if !file.size?
    raise "Config file #{file} was not found or was empty"
  end

  loader = Dsl::Loader.new
  cfg = loader.load_file(file)
end

def read_input
  # # Check if there's input from stdin
  # input = ARGF.read.strip
  #
  # # If no input is found, use command line arguments
  # if input.empty?
  #   input = ARGV.join(' ')
  # end
  input = ARGV.join(' ')

  input.strip
end

def append_to_log(cfg)
  vault = Vault.new(cfg)
  puts vault.path_to_log
end

def main
  cfg = load_config
  input = read_input

  if input.blank?
    $stderr.puts "No input, exiting"
    exit 1
  end

  append_to_log(cfg)
  puts cfg.process_entry_line(input)
end
