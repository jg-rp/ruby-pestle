# frozen_string_literal: true

module Pestle::Grammar
  # An expression matching a single character from a continuous range.
  class Range < Terminal
    attr_reader :start, :stop

    def initialize(start, stop, tag: nil)
      super(tag: tag)
      @start = start
      @stop = stop
      @re = /[#{Regexp.escape(start)}-#{Regexp.escape(stop)}]/
    end

    def to_s
      "#{tag_s}['#{@start}'..'#{@stop}']"
    end

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      !state.scanner.scan(@re).nil?
    end
  end
end
