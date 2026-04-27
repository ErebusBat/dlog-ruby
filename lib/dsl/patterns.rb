module Dsl
  module Patterns
    def noam_phone?
      @noam_phone ||= PatternMatcher.new(
        /(?<!\d)(?:\d{3}-\d{3}-\d{4}|\(\d{3}\)\s*\d{3}-\d{4}|\d{3}\.\d{3}\.\d{4}|\d{10})(?!\d)/x
      )
    end
    alias phone? noam_phone?
  end
end
