# frozen_string_literal: true

module Pestle::Grammar
  # A builtin rule matching any single Unicode character.
  class Any < BuiltInRule
    def initialize
      super("ANY", AnyChar.new, modifier: Rule::SILENT)
    end
  end

  # A terminal expression matching any single Unicode character.
  class AnyChar < Terminal
    def to_s = "ANY"

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      matched = !state.scanner.getch.nil?
      state.track("ANY", matched)
      matched
    end
  end

  # A builtin rule matching the start of the input string.
  class SOI < BuiltInRule
    def initialize
      super("SOI", StartOfInput.new, modifier: Rule::SILENT)
    end
  end

  # A terminal expression matching the start of the input string.
  class StartOfInput < Terminal
    def to_s = "SOI"

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      matched = state.scanner.pos.zero?
      state.track("SOI", matched)
      matched
    end
  end

  # A builtin rule matching the end of the input string.
  class EOI < BuiltInRule
    def initialize
      super("EOI", EndOfInput.new)
    end
  end

  # A terminal expression matching the end of the input string.
  class EndOfInput < Terminal
    def to_s = "EOI"

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      matched = state.scanner.eos?
      state.track("EOI", matched)
      matched
    end
  end

  SPECIAL_RULES = {
    "ANY" => Any.new,
    "SOI" => SOI.new,
    "EOI" => EOI.new
  }.freeze # steep:ignore
end
