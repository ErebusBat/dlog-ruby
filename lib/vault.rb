class Vault
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def assert_have_vault!
    if @config.vault_root.nil?
      raise "Value root was not set!"
    elsif !@config.vault_root.is_a?(Pathname)
      raise "Was expecting vault_root to a Pathname, got #{@config.vault_root}"
    elsif !@config.vault_root.directory?
      raise "Vault root #{@config.vault_root} not found!"
    end
  end

  def path_to_log(day=Date.today)
    assert_have_vault!
    raise "Need a date!" unless day.acts_like_date?

    path = @config.daily_log_finder.call(@config.vault_root, day)
    path = Pathname.new(path)
    raise "Could not find log file for #{day}; #{path} does not exist!" unless path.file?

    path
  end
end
