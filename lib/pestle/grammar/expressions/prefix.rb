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
      state.checkpoint
      matched = @expression.parse(state, [])
      state.restore
      matched
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
      state.neg_pred_depth += 1
      state.checkpoint
      matched = @expression.parse(state, [])
      state.restore

      if matched
        if @expression.is_a?(Identifier)
          label = state.rules[@expression.value].children.first.to_s # steep:ignore
          state.record_failure(label, @expression.value, force: true) # steep:ignore
        elsif @expression.is_a?(Rule)
          state.record_failure(@expression.children.first.to_s, @expression.name, force: true) # steep:ignore
        else
          state.record_failure(@expression.to_s, state.rule_stack.last, force: true)
        end
      end

      state.neg_pred_depth -= 1
      !matched
    end

    def children = [@expression]
  end
end
