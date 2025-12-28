# frozen_string_literal: true

module Pestle::Grammar
  # An expression matching a string literal.
  class StringLiteral < Terminal
    attr_reader :value

    def initialize(value, tag: nil)
      super(tag: tag)
      @value = value
      @re = /#{Regexp.escape(value)}/
    end

    def to_s
      @value.inspect
    end

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      !state.scanner.scan(@re).nil?
    end
  end

  # An expression matching a string literal case insensitively.
  class InsensitiveString < Terminal
    attr_reader :value

    def initialize(value, tag: nil)
      super(tag: tag)
      @value = value
      @re = /#{Regexp.escape(value)}/i
    end

    def to_s
      "^#{@value.inspect}"
    end

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      !state.scanner.scan(@re).nil?
    end
  end
end
