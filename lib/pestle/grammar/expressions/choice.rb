# frozen_string_literal: true

module Pestle::Grammar
  # The choice operator `|`.
  class Choice < Expression
    attr_reader :expressions

    def initialize(*expressions)
      super(tag: nil)
      @expressions = expressions
    end

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end

    def children = @expressions
  end
end
