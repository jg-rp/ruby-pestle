# frozen_string_literal: true

module Pestle::Grammar
  class PushLiteral < Terminal
    attr_reader :value

    def initialize(value, tag: nil)
      super(tag: tag)
      @value = value
    end

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end
  end

  class Push < Expression
    attr_reader :expression

    def initialize(expression, tag: nil)
      super(tag: tag)
      @expression = expression
    end

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
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

    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end
  end

  class Peek < Terminal
    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end
  end

  class PeekAll < Terminal
    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end
  end

  class Pop < Terminal
    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end
  end

  class PopAll < Terminal
    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end
  end

  class Drop < Terminal
    def parse(state, pairs)
      # TODO:
      raise "not implemented"
    end
  end
end
