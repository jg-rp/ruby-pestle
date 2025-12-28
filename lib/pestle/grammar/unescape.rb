# frozen_string_literal: true

module Pestle::Grammar
  SLASH_U_ESCAPE_DIGITS = [2, 4, 6].freeze

  def self.unescape(value, token)
    unescaped = [] # : Array[String]
    index = 0
    length = value.length

    while index < length
      ch = value.byteslice(index) || raise

      unless ch == "\\"
        unescaped << ch
        next
      end

      index += 1

      case value.byteslice(index)
      when "\""
        unescaped << "\""
      when "'"
        unescaped << "'"
      when "\\"
        unescaped << "\\"
      when "/"
        unescaped << "/"
      when "b"
        unescaped << "\x08"
      when "f"
        unescaped << "\x0c"
      when "n"
        unescaped << "\n"
      when "r"
        unescaped << "\r"
      when "t"
        unescaped << "\t"
      when "x"
        # TODO: Handle incomplete or malformed \x escape sequences
        unescaped << value.byteslice((index + 1)...(index + 3)).to_i(16).chr # steep:ignore
        index += 3
      when "u"
        index += 1

        unless value.byteslice(index) == "{"
          raise PestGrammarError.new("expected an opening brace",
                                     token)
        end

        index += 1
        closing_brace_index = value.index("}", index)
        raise PestGrammarError.new("unclosed escape sequence", token) if closing_brace_index.nil?

        hex_digit_length = closing_brace_index - index

        unless SLASH_U_ESCAPE_DIGITS.include?(hex_digit_length)
          raise PestGrammarError.new("expected \\u{00}, \\u{0000} or \\u{000000}", token)
        end

        unescaped << value.byteslice(index...(index + hex_digit_length)).to_i(16).chr # steep:ignore
        index += (hex_digit_length + 1)
      else
        raise PestGrammarError.new("unknown escape sequence", token)
      end

      index += 1
    end

    unescaped.join
  end
end
