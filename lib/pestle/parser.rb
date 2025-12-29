# frozen_string_literal: true

require_relative "grammar/builtin_rules/ascii"
require_relative "grammar/builtin_rules/special"
require_relative "grammar/builtin_rules/unicode"
require_relative "errors"
require_relative "state"

module Pestle
  # A Pest parser.
  class Parser
    # Parse a grammar definition and return a new parser for it.
    def self.from_grammar(grammar)
      rules, doc = Pestle.parse_grammar(grammar)
      new(rules, doc)
    end

    def initialize(rules, doc)
      @rules = {
        **Pestle::Grammar::SPECIAL_RULES,
        **Pestle::Grammar::ASCII_RULES,
        **Pestle::Grammar::UNICODE_RULES,
        **rules
      }

      @doc = doc
      # TODO: optimize
    end

    def parse(start_rule, text, start_pos: 0)
      rule = @rules[start_rule] || raise
      state = ParserState.new(text, @rules, start_pos: start_pos)
      pairs = [] # : Array[Pair]

      # TODO: catch and inject text into errors
      return Pairs.new(pairs) if rule.parse(state, pairs)

      # TODO: error reporting with furthest rule
      raise(PestParsingError, "parsing error")
    end

    def tree_view
      trees = @rules.values.filter do |rule|
        !rule.is_a?(Pestle::Grammar::BuiltInRule)
      end.map(&:tree_view)

      trees.join("\n\n")
    end
  end
end
