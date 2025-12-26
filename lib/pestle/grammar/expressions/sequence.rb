# frozen_string_literal: true

module Pestle::Grammar
  # The sequence operator `~`.
  class Sequence < Expression
    attr_reader :expressions

    def initialize(*expressions)
      super(tag: nil)
      @expressions = expressions
    end

    def parse(state, pairs)
      children = [] # : Array[Pestle::Pair]

      @expression.each_with_index do |expr, i|
        return false unless expr.parse(state, children)

        state.parse_trivia(children) if i < @expressions.length - 1
      end

      pairs.concat(children)
      true
    end

    def children = @expressions
  end
end
