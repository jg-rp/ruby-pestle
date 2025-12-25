# frozen_string_literal: true

module Pestle::Grammar
  # An optional expression `<expression>?`.
  class Optional < Expression
    attr_reader :expression

    def initialize(expression)
      super(tag: nil)
      @expression = expression
    end

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
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

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
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

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
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

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
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

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
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

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
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

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end

    def children = [@expression]
  end
end
