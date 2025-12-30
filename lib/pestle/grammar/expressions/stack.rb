# frozen_string_literal: true

module Pestle::Grammar
  class PushLiteral < Terminal
    attr_reader :value

    def initialize(value, tag: nil)
      super(tag: tag)
      @value = value
    end

    def to_s
      "#{tag_s}PUSH(\"#{value}\")"
    end

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      state.stack_push(@value)
      true
    end
  end

  class Push < Expression
    attr_reader :expression

    def initialize(expression, tag: nil)
      super(tag: tag)
      @expression = expression
    end

    def to_s
      "#{tag_s}PUSH( #{@expression} )"
    end

    def parse(state, pairs)
      start_byte_pos = state.scanner.pos
      children = [] # : Array[Pestle::Pair]

      if @expression.parse(state, children)
        pairs.concat(children)
        state.stack_push(state.text.byteslice(start_byte_pos...state.scanner.pos) || raise)
        true
      else
        false
      end
    end

    def children = [@expression]
  end

  class PeekSlice < Terminal
    attr_reader :start, :stop

    def initialize(start, stop, tag: nil)
      super(tag: tag)
      @start = start
      @stop = stop
    end

    def to_s
      "#{tag_s}PEEK[#{@start}..#{stop}]"
    end

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      start_pos = state.scanner.pos
      state.stack_peek_slice(@start, @stop).each do |s|
        next unless state.scanner.scan(s).nil? # steep:ignore ArgumentTypeMismatch

        state.record_failure(s)
        state.scanner.pos = start_pos
        return false
      end

      true
    end
  end

  class Peek < Terminal
    def to_s
      "#{tag_s}PEEK"
    end

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      peeked = state.stack_peek

      if peeked.nil?
        state.record_failure("PEEK")
        return false
      end

      if state.scanner.scan(peeked).nil? # steep:ignore ArgumentTypeMismatch
        state.record_failure(peeked)
        false
      else
        true
      end
    end
  end

  class PeekAll < Terminal
    def to_s
      "#{tag_s}PEEK_ALL"
    end

    def parse(state, pairs)
      start_pos = state.scanner.pos
      children = [] # : Array[Pestle::Pair]

      state.user_stack.reverse_each.with_index do |s, i|
        if state.scanner.scan(s).nil? # steep:ignore ArgumentTypeMismatch
          state.record_failure(s)
          state.scanner.pos = start_pos
          return false
        end

        state.parse_trivia(children) if i < state.user_stack.length
      end

      pairs.concat(children)
      true
    end
  end

  class Pop < Terminal
    def to_s
      "#{tag_s}POP"
    end

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      peeked = state.stack_peek
      state.record_failure("POP")
      return false if peeked.nil?

      if state.scanner.scan(peeked).nil? # steep:ignore ArgumentTypeMismatch
        state.record_failure(peeked)
        false
      else
        state.stack_pop
        true
      end
    end
  end

  class PopAll < Terminal
    def to_s
      "#{tag_s}POP_ALL"
    end

    def parse(state, pairs)
      start_pos = state.scanner.pos
      children = [] # : Array[Pestle::Pair]

      state.user_stack.reverse_each.with_index do |s, i|
        if state.scanner.scan(s).nil? # steep:ignore ArgumentTypeMismatch
          state.record_failure(s)
          state.scanner.pos = start_pos
          return false
        end

        state.parse_trivia(children) if i < state.user_stack.length
      end

      state.stack_clear
      pairs.concat(children)
      true
    end
  end

  class Drop < Terminal
    def to_s
      "#{tag_s}DROP"
    end

    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      if state.stack_pop.nil?
        state.record_failure("DROP")
        false
      else
        true
      end
    end
  end
end
