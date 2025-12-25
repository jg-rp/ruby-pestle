# frozen_string_literal: true

module Pestle::Grammar
  class Range < Terminal
    attr_reader :start, :stop

    def initialize(start, stop, tag: nil)
      super(tag: tag)
      @start = start
      @stop = stop
    end

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end
  end
end
