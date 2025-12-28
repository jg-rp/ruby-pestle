# frozen_string_literal: true

module Pestle::Grammar
  # A positive predicate expression `&<expression>`.
  class PositivePredicate < Expression
    attr_reader :expression

    def initialize(expression, tag: nil)
      super(tag: tag)
      @expression = expression
    end

    def to_s
      "#{tag_s}&#{@expression}"
    end

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      @expression.parse(state, [])
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

    def to_s
      "#{tag_s}!#{@expression}"
    end

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      state.checkpoint
      matched = @expression.parse(state, [])
      state.restore
      !matched
    end

    def children = [@expression]
  end
end
