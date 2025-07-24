module Dsl
  class LinkSubstitution < Substitution
    attr_reader :page, :alias

    def initialize(search, replace)
      raise "replace should be a hash!" unless replace.is_a?(Hash)

      @search_rx = /#{Regexp.escape(search)}/
      @page = replace[:page].to_s
      @alias = replace[:alias].to_s

      raise "Need at least a page!" if @page.empty?
    end

    def replace_text(_entry)
      link = "[["
      link += page
      if !@alias.empty?
        link += "|#{@alias}"
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
