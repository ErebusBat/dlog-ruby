module Dsl
  class PatternMatcher
    def initialize(pattern)
      @pattern = pattern.is_a?(Regexp) ? pattern : Regexp.new(Regexp.escape(pattern.to_s))
    end

    def to_regexp
      @pattern
    end

    def match(str)
      @pattern.match(str)
    end

    def match?(str)
      @pattern.match?(str)
    end

    def =~(str)
      @pattern =~ str
    end

    def ==(other)
      other.is_a?(PatternMatcher) && @pattern == other.instance_variable_get(:@pattern)
    end
    alias eql? ==

    def hash
      @pattern.hash
    end

    def inspect
      "PatternMatcher(#{@pattern.inspect})"
    end
  end
end
