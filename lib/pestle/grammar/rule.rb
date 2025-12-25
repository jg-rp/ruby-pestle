# frozen_string_literal: true

module Pestle::Grammar
  # A Pest grammar rule.
  class Rule < Expression
    attr_reader :name, :modifier, :doc

    def initialize(name, expression, modifier: nil, doc: nil)
      super(tag: nil)
      @name = name
      @expression = expression
      @modifier = modifier
      @doc = doc
    end

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end

    def children = [@expression]
  end

  class BuiltInRule < Rule
  end
end
