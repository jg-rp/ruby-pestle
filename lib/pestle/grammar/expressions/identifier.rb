# frozen_string_literal: true

module Pestle::Grammar
  # A terminal pointing to a rule, either a grammar rule or a built-in rule.
  class Identifier < Terminal
    attr_reader :value

    def initialize(value, tag: nil)
      super(tag: tag)
      @value = value
    end

    def to_s
      @value
    end

    def parse(state, pairs)
      unless @tag.nil?
        state.with_tag(@tag || raise) do
          return state.rules[@value].parse(state, pairs)
        end
      end
      state.rules[@value].parse(state, pairs)
    end
  end
end
