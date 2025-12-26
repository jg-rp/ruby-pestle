# frozen_string_literal: true

module Pestle
  # User-facing token stream item. The start or end of a rule.
  class Token
    attr_reader :rule, :pos

    def initialize(rule, pos)
      @rule = rule
      @pos = pos
    end
  end

  # A token indicating the start of a rule.
  class Start < Token
    def to_s
      "Start(rule=#{@rule}, pos=#{@pos})"
    end
  end

  # A token indicating the end of a rule.
  class End < Token
    def to_s
      "End(rule=#{@rule}, pos=#{@pos})"
    end
  end

  # A half-open interval [start, end) into the input string.
  # Represents a substring of the input, along with its start and end positions.
  class Span
    attr_reader :text, :start, :end

    def initialize(text, start, stop)
      @text = text
      @start = start
      @end = stop
    end

    def to_s
      @text[@start...@end] || raise
    end

    def start_pos
      Position.new(@text, @start)
    end

    def end_pos
      Position.new(@text, @end)
    end

    # Return an array of lines covered by this span.
    def lines
      lines = @text.lines
      # TODO: avoid `.lines` twice
      start_line_number = start_pos.line_col.first
      end_line_number = end_pos.line_col.first
      lines[(start_line_number - 1)...end_line_number] || raise
    end
  end

  # A position in a string as a Unicode code point offset.
  # Provides utilities for determining line and column numbers.
  class Position
    attr_reader :text, :pos

    def initialize(text, pos)
      @text = text
      @pos = pos
    end

    def line_col
      lines = @text.lines
      cumulative_length = 0
      target_line_index = -1

      lines.each_with_index do |line, i|
        cumulative_length += line.length
        next unless @pos < cumulative_length

        target_line_index = i
        line_number = target_line_index + 1
        column_number = @pos - (cumulative_length - lines[target_line_index].length)
        return [line_number, column_number]
      end

      raise "position is out of bounds for text"
    end

    def line_of
      line_number = line_col.first
      # TODO: avoid `.lines` twice
      @text.lines[line_number - 1]
    end
  end

  # A pair of tokens and everything between them.
  # Represents a node in the parse tree, corresponding to a matched rule and its children.
  class Pair
    include Enumerable

    attr_reader :start, :end, :rule, :tag, :name

    def initialize(source, start, stop, rule, children, tag: nil)
      @source = source
      @start = start
      @end = stop
      @rule = rule
      @children = children
      @tag = tag
      @name = rule.name
    end

    def deconstruct
      [@name, @children, @start, @end]
    end

    def deconstruct_keys(keys) # rubocop: disable Lint/UnusedMethodArgument
      { name: @name, children: @children, start: @start, end: @end }
    end

    def to_s
      @source[@start...@end] || raise
    end

    def each(&block)
      return enum_for(:each) unless block

      @children.each(&block)
    end

    def inner
      Pairs.new(@children)
    end

    def stream
      Stream.new(@children)
    end

    def tokens
      Enumerator.new do |y|
        y << Start.new(@rule, @start)
        @children.each do |child|
          child.tokens.each do |token|
            y << token
          end
        end
        y << End.new(@rule, @end)
      end
    end

    def span
      Span.new(@source, @start, @end)
    end

    def dump
      obj = {
        "rule" => @name,
        "span" => {
          "str" => to_s,
          "start" => @start,
          "end" => @end
        },
        "inner" => @children.map(&:dump)
      }

      obj["node_tag"] = @tag || raise unless @tag.nil?

      obj
    end

    def dumps(indent: 0, new_line: true)
      n = @children.length
      pad = new_line ? "  " * indent : ""
      dash = new_line ? "- " : ""
      pair_tag = @tag.nil? ? "" : "#{@tag} "

      children = @children.map do |pair|
        pair.dumps(indent: n > 1 ? indent + 1 : indent, new_line: n > 1)
      end

      case n
      when 0
        "#{pad}#{dash}#{pair_tag}#{@name}: #{JSON.dump(to_s)}"
      when 1
        "#{pad}#{dash}#{pair_tag}#{@name} > #{children.first}"
      else
        "#{pad}#{dash}#{pair_tag}#{@name}\n#{children.join("\n")}"
      end
    end

    def line_col
      span.start_pos.line_col
    end

    def text
      @source[@start...@end] || raise
    end

    def inner_texts
      @children.map(&:to_s)
    end
  end

  # Enumerable token pairs with utility methods.
  class Pairs
    include Enumerable

    def initialize(pairs)
      @pairs = pairs
    end

    def each(&block)
      return enum_for(:each) unless block

      @pairs.each(&block)
    end

    def length
      @pairs.length
    end

    def tokens
      Enumerator.new do |y|
        @pairs.each do |pair|
          pair.tokens.each do |token|
            y << token
          end
        end
      end
    end

    def stream
      Stream.new(@pairs)
    end

    def dump
      @pairs.map(&:dump)
    end

    def dumps(compact: true)
      if compact
        @pairs.map(&:dumps).join("\n")
      else
        JSON.generate(dump, { indent: "  " })
      end
    end

    def flatten
      Enumerator.new do |y|
        # @type var walk: ^(Pair) -> void
        walk = lambda do |pair|
          y << pair
          pair.each { |child| walk.call(child) }
        end

        @pairs.each { |pair| walk.call(pair) }
      end
    end

    def first
      @pairs.first
    end

    def find_first_tagged(label)
      flatten.each do |pair|
        return pair if pair.tag == label
      end

      nil
    end

    def find_tagged(label)
      Enumerator.new do |y|
        flatten.each do |pair|
          y << pair if pair.tag == label
        end
      end
    end
  end

  # Step through pairs of tokens.
  class Stream
    attr_accessor :pos

    def initialize(pairs)
      @pairs = pairs
      @pos = 0
    end

    # Consume and return the next pair, or nil if we're at the end of the stream.
    def next
      return unless @pos < @pairs.length

      pair = @pairs[@pos]
      @pos += 1
      pair
    end

    # Go back one position. This is a no-op if we're at the beginning of the stream.
    def backup
      @pos -= 1 unless @pos.zero?
    end

    # Return the next pair without consuming it, or nil if we're at the end of the stream.
    def peek
      return unless @pos < @pairs.length

      @pairs[@pos]
    end
  end
end
