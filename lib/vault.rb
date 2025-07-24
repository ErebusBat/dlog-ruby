class Vault
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def path_to_log(day=Date.today)
    raise "Need a date!" unless day.acts_like_date?

    path = @config.daily_log_finder.call(@config.vault_root, day)
    path = Pathname.new(path)
    raise "Could not find log file for #{day}; #{path} does not exist!" unless path.file?

    path
  end
end
