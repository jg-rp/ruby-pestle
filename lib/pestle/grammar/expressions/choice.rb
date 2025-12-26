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
      @expressions.each do |expr|
        state.checkpoint
        children = [] # : Array[Pestle::Pair]
        if expr.parse(state, children)
          state.ok
          pairs.concat(children)
          return true
        end

        state.restore
      end

      false
    end

    def children = @expressions
  end
end
