module Dsl
  class Substitution
    attr_reader :search_rx, :replace

    def initialize(search_rx, replace)
      raise "search_rx should be a Regexp" unless search_rx.is_a?(Regexp)
      @search_rx = search_rx

      if replace.is_a?(String) || replace.is_a?(Proc)
        @replace = replace
      else
        raise "replace must be a string or proc"
      end
    end

    def run(entry)
      match = search_rx.match(entry)
      return entry if match.nil?

      rtxt = replace_text(entry)
      if rtxt.nil?
        entry
      else
        entry.gsub(search_rx, rtxt)
      end
    end

    def replace_text(entry)
      return replace if replace.is_a?(String)
      replace.call(entry)
    end

    def inspect
      if replace.is_a?(Proc)
        "sub(#{search_rx}) (block)"
      else
        "sub(#{search_rx}, '#{replace}')"
      end
    end

    def self.build_prefix(prefix, replace)
      prefix = /^#{Regexp.escape(prefix)}/
      Substitution.new(prefix, replace)
    end

    def self.build_gsub(search, replace)
      search = /#{Regexp.escape(search)}/ unless search.is_a?(Regexp)
      Substitution.new(search, replace)
    end
  end
end

