# frozen_string_literal: true

module Pestle::Grammar
  # An expression surrounded by parentheses.
  class Group < Expression
    attr_reader :expression

    def initialize(expression, tag: nil)
      super(tag: tag)
      @expression = expression
    end

    def to_s
      "#{tag_s}(#{@expression})"
    end

    def parse(state, pairs)
      return @expression.parse(state, pairs) unless @tag

      state.with_tag(@tag || raise) do
        return @expression.parse(state, pairs)
      end
    end

    def children = [@expression]
  end
end
