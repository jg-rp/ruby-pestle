# frozen_string_literal: true

# Pest grammar parsing and evaluation.
module Pestle::Grammar
  # A builtin rule matching ASCII character ranges.
  class ASCIIRule < BuiltInRule
    def initialize(name, *ranges)
      expr = if ranges.length == 1
               range = ranges.first
               Range.new(range.first, range.last)
             else
               Choice.new(*ranges.map { |r| Range.new(r.first, r.last) })
             end

      super(name, expr, modifier: Rule::SILENT)
    end
  end

  ASCII_RULE_DEFS = {
    "ASCII_DIGIT" => [%w[0 9]],
    "ASCII_NONZERO_DIGIT" => [%w[1 9]],
    "ASCII_BIN_DIGIT" => [%w[0 1]],
    "ASCII_OCT_DIGIT" => [%w[0 7]],
    "ASCII_HEX_DIGIT" => [%w[0 9], %w[a f], %w[A F]],
    "ASCII_ALPHANUMERIC" => [%w[0 9], %w[a z], %w[A Z]],
    "ASCII" => [["\u0000", "\u007f"]],
    "ASCII_ALPHA_LOWER" => [%w[a z]],
    "ASCII_ALPHA_UPPER" => [%w[A Z]],
    "ASCII_ALPHA" => [%w[a z], %w[A Z]]
  }.freeze

  ASCII_RULES = ASCII_RULE_DEFS.to_h { |name, ranges| [name, ASCIIRule.new(name, *ranges)] }
  ASCII_RULES["NEWLINE"] =
    BuiltInRule.new("NEWLINE",
                    Choice.new(StringLiteral.new("\n"), StringLiteral.new("\r\n"),
                               StringLiteral.new("\r")), modifier: Rule::SILENT)
  ASCII_RULES.freeze
end
