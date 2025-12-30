# frozen_string_literal: true

module Pestle::Grammar
  # A Pest grammar rule.
  class Rule < Expression
    attr_reader :name, :modifier, :doc

    SILENT = 1 << 0
    ATOMIC = 1 << 1
    COMPOUND = 1 << 2
    NONATOMIC = 1 << 3

    SILENT_ATOMIC = SILENT | ATOMIC
    SILENT_COMPOUND = SILENT | COMPOUND
    SILENT_NONATOMIC = SILENT | NONATOMIC

    def initialize(name, expression, modifier: 0, doc: nil)
      super(tag: nil)
      @name = name
      @expression = expression
      @modifier = modifier
      @doc = doc
    end

    def to_s
      modifier = case @modifier
                 when SILENT
                   "_"
                 when ATOMIC
                   "@"
                 when COMPOUND
                   "$"
                 when NONATOMIC
                   "!"
                 else
                   ""
                 end

      "#{@name} = #{modifier}{ #{@expression} }"
    end

    def parse(state, pairs)
      start_pos = state.scanner.pos
      children = [] # : Array[Pestle::Pair]
      matched = false

      state.rule_stack << @name

      # TODO: ensure COMMENT and WHITESPACE are atomic during parsing
      if @modifier.anybits?(ATOMIC | COMPOUND)
        state.atomic do
          matched = @expression.parse(state, children)
        end
      elsif @modifier.anybits?(NONATOMIC)
        state.nonatomic do
          matched = @expression.parse(state, children)
        end
      else
        matched = @expression.parse(state, children)
      end

      state.rule_stack.pop
      tag = state.tags.pop

      return false unless matched

      if @modifier.anybits?(SILENT)
        pairs.concat(children)
        return true
      end

      if @modifier.anybits?(ATOMIC)
        # @type var rule: Rule?
        # steep:ignore:start
        rule = if @expression.is_a?(Rule)
                 @expression
               elsif @expression.is_a?(Identifier)
                 state.rules[@expression.value]
               end
        # steep:ignore:end

        if rule.nil? || rule.modifier.nobits?(NONATOMIC | COMPOUND)
          # Atomic rule silences children.
          children = [] # : Array[Pestle::Pair]
        end
      end

      pairs << Pestle::Pair.new(state.text, start_pos, state.scanner.pos, @name, children, tag: tag)

      true
    end

    def children = [@expression]
  end

  class BuiltInRule < Rule
  end
end
