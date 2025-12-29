# frozen_string_literal: true

module Pestle::Grammar
  # An optional expression `<expression>?`.
  class Optional < Expression
    attr_reader :expression

    def initialize(expression)
      super(tag: nil)
      @expression = expression
    end

    def to_s
      "#{@expression}?"
    end

    def parse(state, pairs)
      children = [] # : Array[Pestle::Pair]
      pairs.concat(children) if @expression.parse(state, children)
      true
    end

    def children = [@expression]
  end

  # An expression repeated zero or more times `<expression>*`.
  class Repeat < Expression
    attr_reader :expression

    def initialize(expression)
      super(tag: nil)
      @expression = expression
    end

    def to_s
      "#{@expression}*"
    end

    def parse(state, pairs)
      children = [] # : Array[Pestle::Pair]
      loop do
        state.checkpoint
        if @expression.parse(state, children)
          state.ok
          pairs.concat(children)
          children.clear
          state.parse_trivia(children)
        else
          state.restore
          break
        end
      end
      true # Always succeed
    end

    def children = [@expression]
  end

  # An expression repeated one or more times `<expression>+`.
  class RepeatOnce < Expression
    attr_reader :expression

    def initialize(expression)
      super(tag: nil)
      @expression = expression
    end

    def to_s
      "#{@expression}+"
    end

    def parse(state, pairs)
      children = [] # : Array[Pestle::Pair]

      state.checkpoint
      if @expression.parse(state, children)
        state.ok
        pairs.concat(children)
        children.clear
        state.parse_trivia(children)
      else
        state.restore
        return false
      end

      loop do
        state.checkpoint
        if @expression.parse(state, children)
          state.ok
          pairs.concat(children)
          children.clear
          state.parse_trivia(children)
        else
          state.restore
          break
        end
      end

      true
    end

    def children = [@expression]
  end

  # An expression repeated a specified number of times `<expression>{n}`.
  class RepeatExact < Expression
    attr_reader :expression, :number

    def initialize(expression, number)
      super(tag: nil)
      @expression = expression
      @number = number
    end

    def to_s
      "#{@expression}{#{@number}}"
    end

    def parse(state, pairs)
      return true if @number.zero?

      children = [] # : Array[Pestle::Pair]
      count = 0

      state.checkpoint

      loop do
        state.parse_trivia(children)
        break unless @expression.parse(state, children)

        count += 1

        break if count == @number
      end

      if count == @number
        pairs.concat(children)
        state.ok
        true
      else
        state.restore
        false
      end
    end

    def children = [@expression]
  end

  # An expression repeated at least specified number of times `<expression>{n,}`.
  class RepeatMin < Expression
    attr_reader :expression, :number

    def initialize(expression, number)
      super(tag: nil)
      @expression = expression
      @number = number
    end

    def to_s
      "#{@expression}{#{@number},}"
    end

    def parse(state, pairs)
      return true if @number.zero?

      children = [] # : Array[Pestle::Pair]
      count = 0

      state.checkpoint

      loop do
        state.parse_trivia(children)
        break unless @expression.parse(state, children)

        count += 1
      end

      if count >= @number
        pairs.concat(children)
        state.ok
        true
      else
        state.restore
        false
      end
    end

    def children = [@expression]
  end

  # An expression repeated at most specified number of times `<expression>{,n}`.
  class RepeatMax < Expression
    attr_reader :expression, :number

    def initialize(expression, number)
      super(tag: nil)
      @expression = expression
      @number = number
    end

    def to_s
      "#{@expression}{,#{@number}}"
    end

    def parse(state, pairs)
      return true if @number.zero?

      children = [] # : Array[Pestle::Pair]
      count = 0

      state.checkpoint

      loop do
        state.parse_trivia(children)
        break unless @expression.parse(state, children)

        count += 1

        break if count == @number
      end

      pairs.concat(children)
      state.ok
      true
    end

    def children = [@expression]
  end

  # An expression repeated a specified range of times `<expression>{n,m}`.
  class RepeatMinMax < Expression
    attr_reader :expression, :min, :max

    def initialize(expression, min, max)
      super(tag: nil)
      @expression = expression
      @min = min
      @max = max
    end

    def to_s
      "#{@expression}{#{@min},#{@max}}"
    end

    def parse(state, pairs)
      children = [] # : Array[Pestle::Pair]
      count = 0

      state.checkpoint

      loop do
        state.parse_trivia(children)
        break unless @expression.parse(state, children)

        count += 1

        break if count == @max
      end

      if count.between?(@min, @max)
        pairs.concat(children)
        state.ok
        true
      else
        state.restore
        false
      end
    end

    def children = [@expression]
  end
end
