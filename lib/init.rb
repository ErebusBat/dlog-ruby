require_relative 'dsl'
require_relative 'vault'

def config_file_path
  [
    ENV['DLOG_CONFIG'],
    "~/.config/dlog/vault.rb",
    "./vault_config.rb"
  ].each do |candidate_path|
    next if candidate_path.blank?

    candidate_path = Pathname.new(candidate_path).expand_path
    return candidate_path if candidate_path.readable?
  end
  nil
end

def load_config(file='config/vault.rb')
  file = Pathname.new(file)
  if !file.size?
    raise "Config file #{file} was not found or was empty"
  end

  loader = Dsl::Loader.new
  cfg = loader.load_file(file)
end

def find_and_load_user_config
  cfg_path = config_file_path
  unless cfg_path.present?
    raise "Could not find config file in ~/.config/dlog/vault.rb"
  end

  load_config(cfg_path)
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

def append_to_log(cfg, entry, day: Date.today)
  vault = Vault.new(cfg)
  daily_log = vault.path_to_log(day)

  # cfg.dbug "Appending entry to log:\n\tlog: #{daily_log}\n\ttxt: #{entry}"
  daily_log.open('a') do |file|
    file.puts entry
  end
end

def main
  cfg = find_and_load_user_config
  input = read_input

  if input.blank?
    $stderr.puts "No input, exiting"
    exit 1
  end

  entry = cfg.process_entry_line(input)
  if entry.blank?
    $stderr.puts "Entry was blank, exiting"
    exit 2
  end

  append_to_log(cfg, entry)
  puts entry
end
