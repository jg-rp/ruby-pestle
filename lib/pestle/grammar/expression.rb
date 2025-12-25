# frozen_string_literal: true

module Pestle::Grammar
  # Base class for all Pest grammar expressions.
  class Expression
    attr_reader :tag # : String?

    def initialize(tag: nil)
      @tag = tag
    end

    # Try to match this expression at the current position defined by `state`.
    # Append new token pairs to `pairs`.
    # @return `True` if the match was successful, `False` otherwise.
    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      raise "all expressions must implement `parse: (ParserState, Array[Pair]) -> bool`"
    end

    # Return this expressions direct child expressions.
    def children
      raise "all expressions must implement `children: () -> Array[Expression]`"
    end
  end

  # Base class for terminal expressions (those without children).
  class Terminal < Expression
    def children = []
  end
end
