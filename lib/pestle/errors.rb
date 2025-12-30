# frozen_string_literal: true

module Pestle
  # Pest parsing error.
  class PestParsingError < StandardError
    attr_reader :state

    FULL_MESSAGE = ((RUBY_VERSION.split(".")&.map(&:to_i) <=> [3, 2, 0]) || -1) < 1

    def self.expected(state)
      if !state.furthest_expected.empty? && state.furthest_unexpected.empty?
        "expected #{state.furthest_expected.keys.join(" or ")}"
      elsif !state.furthest_expected.empty? && !state.furthest_unexpected.empty?
        expected = "expected #{state.furthest_expected.keys.join(" or ")}"
        unexpected = "unexpected #{state.furthest_unexpected.keys.join(" or ")}"
        "#{unexpected}; #{expected}"
      elsif !state.furthest_unexpected.empty?
        "unexpected #{state.furthest_unexpected.keys.join(" or ")}"
      else
        "pest parsing error"
      end
    end

    def initialize(message, state)
      super(message)
      @state = state
    end

    def detailed_message(highlight: true, **kwargs)
      line, col, current_line = error_context(@state.text, @state.furthest_pos)

      pad = " " * line.to_s.length
      pointer = (" " * (col - 1)) + "^"
      no_pointer = " " * col
      rule_stack = @state.furthest_rules.join(" > ")

      <<~MESSAGE.strip
        #{message}
        #{pad} -> #{rule_stack} #{line}:#{col}
        #{pad} |
        #{line} | #{current_line}
        #{pad} | #{pointer} #{highlight ? "\e[1m#{message}\e[0m" : message}
        #{pad} | #{no_pointer} (#{expected_labels})
      MESSAGE
    end

    def full_message(highlight: true, order: :top)
      if FULL_MESSAGE
        # For Ruby < 3.2.0
        "#{super}\n#{detailed_message(highlight: highlight, order: order)}"
      else
        super
      end
    end

    protected

    # TODO: smart join

    def expected_labels
      if !@state.furthest_expected.empty? && @state.furthest_unexpected.empty?
        "expected #{@state.furthest_expected.values.flatten.join(", ")}"
      elsif !@state.furthest_expected.empty? && !@state.furthest_unexpected.empty?
        expected = "expected #{@state.furthest_expected.values.flatten.join(", ")}"
        unexpected = "unexpected #{@state.furthest_unexpected.values.join(", ")}"
        "#{unexpected}; #{expected}"
      elsif !@state.furthest_unexpected.empty?
        "unexpected #{@state.furthest_unexpected.values.flatten.join(", ")}"
      else
        "no context available"
      end
    end

    def error_context(text, byte_index)
      lines = text.lines
      cumulative_length = 0
      target_line_index = -1

      lines.each_with_index do |line, i|
        cumulative_length += line.bytesize
        if byte_index < cumulative_length
          target_line_index = i
          break
        end
      end

      return [lines.length, lines.last.length + 1, lines.last] if target_line_index == -1

      current_line = lines[target_line_index]

      # Column numbers are in Unicode code points, not bytes or grapheme clusters.
      byte_column_index = byte_index - (cumulative_length - current_line.bytesize)
      column_number = (current_line.byteslice(0, byte_column_index) || current_line).length + 1

      [target_line_index + 1, column_number, current_line]
    end
  end
end
