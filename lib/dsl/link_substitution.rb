module Dsl
  class LinkSubstitution < Substitution
    attr_reader :page, :display

    def initialize(search, page: , display: nil)
      @search_rx = /#{Regexp.escape(search)}/
      @page = page.to_s
      @display = display.to_s

      raise "Need at least a page!" if @page.empty?
    end

    def replace_text(_entry)
      link = "[["
      link += page
      if !@display.empty?
        link += "|#{@display}"
      end
      link += "]]"

      link
    end

    def inspect
      if replace.is_a?(Proc)
        "link_gsub(#{search_rx}) (block)"
      else
        "link_gsub(#{search_rx}, '#{replace}')"
      end
    end
  end
end
