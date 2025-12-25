# frozen_string_literal: true

module Pestle::Grammar
  # A positive predicate expression `&<expression>`.
  class PositivePredicate < Expression
    attr_reader :expression

    def initialize(expression, tag: nil)
      super(tag: tag)
      @expression = expression
    end

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end

    def children = [@expression]
  end

  # A negative predicate expression `!<expression>`.
  class NegativePredicate < Expression
    attr_reader :expression

    def initialize(expression, tag: nil)
      super(tag: tag)
      @expression = expression
    end

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end

    def children = [@expression]
  end
end
