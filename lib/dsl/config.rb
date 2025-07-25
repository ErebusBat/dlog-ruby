module Dsl
  class Config
    attr_reader :vault_root, :daily_log_finder, :gsubs, :prefixes, :entry_prefix, :tool_path

    def initialize
      @vault_root = nil
      @daily_log_finder = nil
      @gsubs = {}
      @prefixes = {}
      @tool_paths = {}
      @tool_ec = 0
      @tool_output = nil
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
      if replace.is_a?(String)
        replace = "#{replace} " unless replace.ends_with?(' ')
      end
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
      elsif replace.is_a?(Hash)
        if replace.has_key?(:alias)
          # Alias provides better ergonomics in the DSL, but is a reserved word
          # so it messes things up so we do this
          replace[:display] = replace.delete(:alias)
        end
      end
      @gsubs[search] = LinkSubstitution.new(search, **replace)
    end

    ################################################################################
    ### File / Dir Helpers
    ################################################################################
    def dir?(path)
      path = Pathname.new(path).expand_path
      path.directory?
    end

    ################################################################################
    ### Debugging
    ################################################################################
    def dbug(text)
      $stderr.puts "[#{Time.now}] #{text}"
    end

    ################################################################################
    ### Clipboad
    ################################################################################
    def get_clipboard
      `pbpaste`.strip
    end

    def set_clipboard(text)
      Tempfile.create do |tmp|
        tmp.print text
        tmp.flush
        tmp.close

        system("/bin/cat #{tmp.path} | pbcopy")
      end
    end

    ################################################################################
    ### Tools
    ################################################################################
    def set_tool_path(path)
      @tool_path = path
      @tool_output = nil
      @tool_ec = -666
      find_path_to_tool(@tool_path)
    end

    def has_tool?(tool=tool_path)
      !!find_path_to_tool(tool)
    end

    def run_tool(tool=tool_path, args=nil)
      set_tool_path(tool) # Will reset output and ec
      raise "Could not find tool '#{tool}'" unless has_tool?(tool)

      tool_path = find_path_to_tool(tool)
      @tool_output = `#{tool_path} #{args}`.strip
      @tool_ec = $?.to_i
      @tool_output
    end

    def tool_ec; @tool_ec; end

    def tool_success?
      tool_ec == 0
    end

    def tool_error?
      tool_ec != 0
    end

    def tool_output
      @tool_output
    end

    def find_path_to_tool(tool=tool_path)
      # Check Cache
      path = @tool_paths[tool.to_s]
      return if path == false
      return path if path.is_a?(Pathname)

      # Not in cache, so find it on disk
      if tool.include?("/")
        # We have some sort of path
        path = Pathname.new(tool).expand_path
      else
        # No path, try to find it
        path = `which #{tool}`.strip
        path = Pathname.new(path).expand_path
      end

      # Sanity Checks
      if path.executable?
        @tool_paths[tool] = path
      else
        # Could not find it, cache bad result
        @tool_paths[tool] = false
        return
      end

      @tool_paths[tool]
    end

    ################################################################################
    ### Helper methods
    ################################################################################
    def assert_gsub_not_present!(key)
      return unless @gsubs.has_key?(key)

      raise "You attempted to add a global substitution (gsub) named '#{key}' that has already been configured!"
    end

    def assert_prefix_not_present!(key)
      return unless @prefixes.has_key?(key)

      raise "You attempted to add a prefix substitution named '#{key}' that has already been configured!"
    end

    def process_entry_line(input, ts: Time.now)
      entry_text = process_entry_text(input)

      prefix = ""
      if @entry_prefix.present?
        prefix = @entry_prefix.call(entry_text, ts)
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

      entry.strip
    end

    def to_h
      h = { vault: @vault_root.to_s }

      h[:prefix] = @prefixes.map(&:inspect)
      h[:gsub] = @gsubs.map(&:inspect)

      h
    end
  end
end
