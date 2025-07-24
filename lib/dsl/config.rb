module Dsl
  class Config
    attr_reader :vault_root, :daily_log_finder, :gsubs, :prefixes, :entry_prefix

    def initialize
      @vault_root = nil
      @daily_log_finder = nil
      @gsubs = {}
      @prefixes = {}
    end

    def set_vault_root(path)
      path = Pathname.new(path).expand_path
      raise "Vault path not found (#{path})" unless path.directory?

      @vault_root = path
    end

    def set_daily_log_finder(&block)
      raise "You must pass a block to this method!" unless block_given?

      parameters = block.parameters
      if parameters.count != 2
        raise "Your block signature is incorrect, it should be `|vault, day|` Got: #{parameters}"
      end

      @daily_log_finder = block
    end

    def set_entry_prefix(static=nil, &block)
      if static.to_s.empty? && !block_given?
        raise "You need to provide a prefix or block"
      end

      if block_given?
        @entry_prefix = block
      else
        @entry_prefix = Proc.new { |entry| static.to_s }
      end
    end

    def add_gsub(search, replace=nil, &block)
      assert_gsub_not_present!(search)

      if block_given?
        raise "You can not specify a replace value AND a block" unless replace.nil?
        actual_params = block.parameters
        raise "Invalid gsub block signature, it should just be `|entry|` Got: #{actual_params}" unless actual_params.count == 1

        replace = block
      end

      @gsubs[search] = Substitution.build_gsub(search, replace)
    end

    def add_prefix(prefix, replace)
      assert_prefix_not_present!(prefix)

      @prefixes[prefix] = Substitution.build_prefix(prefix, replace)
    end

    def add_link_gsub(search, replace)
      assert_gsub_not_present!(search)

      if replace.is_a?(String)
        if replace.start_with?('[[')
          # Remove braces
          replace = replace[/^\[+([^\[\]]+)\]+/, 1]
        end
        replace = { page: replace }
      end
      @gsubs[search] = LinkSubstitution.new(search, replace)
    end

    @tool_paths = {}
    def find_path_to_tool(tool)
      # Check Cache
      path = @tool_paths[tool.to_s]
      return if path == false
      return path if path.is_a?(Pathname)

      # Not in cache, so find it on disk
      path = `which #{tool}`.strip
      path = Pathname.new(path).expand_path
      if path.executable?
        @tool_paths[tool] = path
      else
        # Could not find it, cache bad result
        @tool_paths[tool] = false
        return
      end

      @tool_paths[tool]
    end

    def has_tool?(tool)
      !!find_path_to_tool(tool)
    end

    def run_tool(tool, args)
      raise "Could not find tool '#{tool}'" unless has_tool?(tool)

      tool_path = find_path_to_tool(tool)
      `#{tool_path} #{args}`.strip
    end

    def assert_gsub_not_present!(key)
      return unless @gsubs.has_key?(key)

      raise "You attempted to add a global substitution (gsub) named '#{key}' that has already been configured!"
    end

    def assert_prefix_not_present!(key)
      return unless @prefixes.has_key?(key)

      raise "You attempted to add a prefix substitution named '#{key}' that has already been configured!"
    end

    def process_entry_line(input)
      entry_text = process_entry_text(input)

      prefix = ""
      if @entry_prefix.present?
        prefix = @entry_prefix.call(entry_text)
      end

      [prefix, entry_text].join
    end

    def process_entry_text(entry)
      @prefixes.each do |key, sub|
        entry = sub.run(entry)
      end
      @gsubs.each do |key, sub|
        entry = sub.run(entry)
      end
      entry
    end

    def to_h
      h = { vault: @vault_root.to_s }

      h[:prefix] = @prefixes.map(&:inspect)
      h[:gsub] = @gsubs.map(&:inspect)

      h
    end
  end
end
