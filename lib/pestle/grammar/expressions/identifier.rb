# frozen_string_literal: true

module Pestle::Grammar
  class Identifier < Terminal
    attr_reader :value

    def initialize(value, tag: nil)
      super(tag: tag)
      @value = value
    end

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end
  end
end
