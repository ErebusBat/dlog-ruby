module Dsl
  class Substitution
    attr_reader :search_rx, :replace

    def initialize(search_rx, replace)
      unless search_rx.is_a?(Regexp) || search_rx.is_a?(PatternMatcher)
        raise "search_rx should be a Regexp or PatternMatcher"
      end
      @search_rx = search_rx

      if replace.is_a?(String) || replace.is_a?(Proc)
        @replace = replace
      else
        raise "replace must be a string or proc"
      end
    end

    def run(entry)
      pattern = search_rx.respond_to?(:to_regexp) ? search_rx.to_regexp : search_rx
      entry.gsub(pattern) do |match|
        rtxt = replace_text(entry, match)

        # If the replace text is nil, that means the gsub was a no-op
        # If a tool wants to remove the match, it should return ""
        rtxt.nil? ? match : rtxt
      end
    end

    def replace_text(entry, match)
      return replace if replace.is_a?(String)
      replace.call(entry, match)
    end

    def inspect
      if replace.is_a?(Proc)
        "sub(#{search_rx}) (block)"
      else
        "sub(#{search_rx}, '#{replace}')"
      end
    end

    def self.build_prefix(prefix, replace)
      prefix = /^#{Regexp.escape(prefix)}(\s|$)/
      Substitution.new(prefix, replace)
    end

    def self.build_gsub(search, replace)
      unless search.is_a?(Regexp) || search.is_a?(PatternMatcher)
        search = /#{Regexp.escape(search)}/
      end
      Substitution.new(search, replace)
    end
  end
end

