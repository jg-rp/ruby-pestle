# frozen_string_literal: true

require "strscan"

module Pestle::Grammar
  # Pest grammar tokenizer.
  class Lexer
    attr_reader :tokens

    RE_BLOCK_COMMENT_CHUNK = %r{(/\*|\*/)}
    RE_BLOCK_COMMENT_END = %r{\*/}
    RE_BLOCK_COMMENT_START = %r{/\*}
    RE_CHAR = /'(\\[\\"\r\n\t\0']|\\x[0-9a-fA-F]{2}|\\u\{[0-9a-fA-F]{2,6}\}|.)'/
    RE_DROP = /DROP/
    RE_GRAMMAR_DOC = %r{//![ \t]*(.*)}
    RE_IDENT = /[_a-zA-Z][_a-zA-Z0-9]*/
    RE_INTEGER = /-?[0-9]+/
    RE_LINE_COMMENT = %r{//(?![/!]).*}
    RE_NUMBER = /[0-9]+/
    RE_PEEK = /PEEK/
    RE_PEEK_ALL = /PEEK_ALL/
    RE_POP = /POP/
    RE_POP_ALL = /POP_ALL/
    RE_PUSH = /PUSH/
    RE_PUSH_LITERAL = /PUSH_LITERAL/
    RE_RANGE_OP = /\.\./
    RE_RULE_DOC = %r{///[ \t]*(.*)}
    RE_TAG = /#([_a-zA-Z][_a-zA-Z0-9]+)(?=\s*=)/
    RE_WHITESPACE = /[ \t\n\r]+/

    def self.tokenize(grammar)
      lexer = new(grammar)
      lexer.lex_grammar
      lexer.tokens
    end

    def initialize(grammar)
      @grammar = grammar
      @scanner = StringScanner.new(grammar)

      # Start of the current token as a byte index into grammar.
      @start = 0

      # Tokens are arrays of (kind, value, start index).
      # Sometimes we set value to `nil` when the symbol is unambiguous.
      @tokens = [] # : Array[[Symbol, String?, Integer]]
    end

    def lex_grammar
      skip_trivia
      while @scanner.scan(RE_GRAMMAR_DOC)
        @tokens << [:token_grammar_doc, @scanner.captures&.first || raise, @start]
        @start = @scanner.pos
        skip_trivia
      end

      lex_rules
      @tokens << [:token_eof, nil, @scanner.pos]
    end

    protected

    def skip?(regex)
      if @scanner.skip(regex)
        @start = @scanner.pos
        return true
      end
      false
    end

    def skip_block_comment?
      if @scanner.scan(RE_BLOCK_COMMENT_START)
        depth = 1
        loop do
          break unless @scanner.skip_until(RE_BLOCK_COMMENT_CHUNK)

          case @scanner.captures&.first || raise
          when "/*"
            depth += 1
          when "*/"
            depth -= 1
            next if depth.positive?

            @start = @scanner.pos
          end
        end
        return true
      end
      false
    end

    def skip_trivia
      loop do
        break unless skip?(RE_WHITESPACE) || skip?(RE_LINE_COMMENT) || skip_block_comment?
      end
    end

    def lex_rules
      loop do
        skip_trivia
        while @scanner.scan(RE_RULE_DOC)
          @tokens << [:token_rule_doc, @scanner.captures&.first || raise, @start]
          @start = @scanner.pos
          skip_trivia
        end

        return if @scanner.eos?

        if (value = @scanner.scan(RE_IDENT))
          @tokens << [:token_ident, value, @start]
          @start = @scanner.pos
        else
          raise "expected a rule"
        end

        skip_trivia

        # Assignment operator
        raise "expected the assignment operator" unless @scanner.scan_byte == 61 # =

        @tokens << [:token_assign_op, nil, @start]
        @start = @scanner.pos

        skip_trivia

        # Optional modifier
        case @scanner.peek_byte # steep:ignore NoMethod
        when 95 # _
          @scanner.pos += 1
          @tokens << [:token_mod_silent, nil, @start]
          @start = @scanner.pos
        when 64 # @
          @scanner.pos += 1
          @tokens << [:token_mod_atomic, nil, @start]
          @start = @scanner.pos
        when 36 # $
          @scanner.pos += 1
          @tokens << [:token_mod_compound, nil, @start]
          @start = @scanner.pos
        when 33 # !
          @scanner.pos += 1
          @tokens << [:token_mod_non_atomic, nil, @start]
          @start = @scanner.pos
        end

        # Opening brace
        raise "expected an opening brace" unless @scanner.scan_byte == 123 # {

        @tokens << [:token_l_brace, nil, @start]
        @start = @scanner.pos

        accept_expression

        # Closing brace
        raise "expected a closing brace" unless @scanner.scan_byte == 125 # }

        @tokens << [:token_r_brace, nil, @start]
        @start = @scanner.pos
      end
    end

    def accept_expression
      skip_trivia

      # Ignore leading choice op '|'
      if @scanner.peek_byte == 124 # steep:ignore
        @scanner.pos += 1
        skip_trivia
      end

      accept_term

      loop do
        skip_trivia
        case @scanner.peek_byte # steep:ignore
        when 126 # ~
          @scanner.pos += 1
          @tokens << [:token_sequence_op, nil, @start]
          @start = @scanner.pos
          skip_trivia
          accept_term
        when 124 # |
          @scanner.pos += 1
          @tokens << [:token_choice_op, nil, @start]
          @start = @scanner.pos
          skip_trivia
          accept_term
        else
          break
        end
      end
    end

    def accept_term
      # Optional tag
      # "#" ~ identifier ~ "="
      if @scanner.scan(RE_TAG)
        @tokens << [:token_tag, @scanner.captures&.first || raise, @start]
        @start = @scanner.pos
        skip_trivia
        @scanner.pos += 1 # Move past '='
        @tokens << [:token_assign_op, nil, @start]
        @start = @scanner.pos
        skip_trivia
      end

      # Optional predicate prefix operator
      case @scanner.peek_byte # steep:ignore
      when 38 # &
        @scanner.pos += 1
        @tokens << [:token_pos_pred, nil, @start]
        @start = @scanner.pos
      when 33 # !
        while @scanner.peek_byte == 33 # steep:ignore
          @scanner.pos += 1
          @tokens << [:token_neg_pred, nil, @start]
          @start = @scanner.pos
        end
      end

      unless accept_terminal?
        # "(" ~ expression ~ ")"
        raise "expected an opening parenthesis" unless @scanner.scan_byte == 40 # (

        @tokens << [:token_l_paren, nil, @start]
        @start = @scanner.pos

        skip_trivia
        accept_expression
        skip_trivia

        raise "expected a closing parenthesis" unless @scanner.scan_byte == 41 # )

        @tokens << [:token_r_paren, nil, @start]
        @start = @scanner.pos
      end

      accept_postfix_op
    end

    def accept_terminal?
      if @scanner.scan(RE_PUSH_LITERAL)
        # "PUSH_LITERAL" ~ "(" ~ string_literal ~ ")"
        @tokens << [:token_push_literal, nil, @start]
        @start = @scanner.pos

        skip_trivia
        raise "expected an opening parenthesis" unless @scanner.scan_byte == 40 # (

        @start = @scanner.pos
        skip_trivia
        raise "expected a string literal" unless accept_string_literal?

        skip_trivia
        raise "expected an opening parenthesis" unless @scanner.scan_byte == 41 # )

        return true
      end

      if @scanner.scan(RE_PUSH)
        # "PUSH" ~ "(" ~ expression ~ ")"
        @tokens << [:token_push_expr, nil, @start]
        @start = @scanner.pos

        skip_trivia
        raise "expected an opening parenthesis" unless @scanner.scan_byte == 40 # (

        @start = @scanner.pos
        skip_trivia
        accept_expression

        skip_trivia
        raise "expected an opening parenthesis" unless @scanner.scan_byte == 41 # )

        return true
      end

      if @scanner.scan(RE_PEEK_ALL)
        @tokens << [:token_peek_all, nil, @start]
        @start = @scanner.pos
        return true
      end

      if @scanner.scan(RE_POP_ALL)
        @tokens << [:token_pop_all, nil, @start]
        @start = @scanner.pos
        return true
      end

      if @scanner.scan(RE_POP)
        @tokens << [:token_pop, nil, @start]
        @start = @scanner.pos
        return true
      end

      if @scanner.scan(RE_DROP)
        @tokens << [:token_drop, nil, @start]
        @start = @scanner.pos
        return true
      end

      if @scanner.scan(RE_PEEK)
        @tokens << [:token_peek, nil, @start]
        @start = @scanner.pos

        # Optional slice
        return true unless @scanner.peek_byte == 91 # steep:ignore

        @scanner.pos += 1
        @tokens << [:token_l_bracket, nil, @start]
        @start = @scanner.pos

        if (value = @scanner.scan(RE_INTEGER))
          @tokens << [:token_INTEGER, value, @start]
          @start = @scanner.pos
        end

        raise "expected a range operator" unless @scanner.scan(RE_RANGE_OP)

        @tokens << [:token_range_op, nil, @start]
        @start = @scanner.pos

        if (value = @scanner.scan(RE_INTEGER))
          @tokens << [:token_INTEGER, value, @start]
          @start = @scanner.pos
        end

        raise "expected a closing bracket" unless @scanner.scan_byte == 93 # "]"

        @tokens << [:token_r_bracket, nil, @start]
        @start = @scanner.pos

        return true
      end

      if (value = @scanner.scan(RE_IDENT))
        @tokens << [:token_ident, value, @start]
        @start = @scanner.pos
        return true
      end

      return true if accept_string_literal? || accept_ci_string_literal?

      if @scanner.scan(RE_CHAR)
        # char ~ ".." ~ char
        @tokens << [:token_char, @scanner.captures&.first || raise, @start]
        @start = @scanner.pos

        skip_trivia
        raise "expected a range operator" unless @scanner.scan(RE_RANGE_OP)

        @tokens << [:token_range_op, nil, @start]
        @start = @scanner.pos

        skip_trivia
        raise "expected a character literal" unless @scanner.scan(RE_CHAR)

        @tokens << [:token_char, @scanner.captures&.first || raise, @start]
        @start = @scanner.pos

        return true
      end

      false
    end

    def accept_postfix_op
      case @scanner.peek_byte # steep:ignore
      when 63 # ?
        @scanner.pos += 1
        @tokens << [:token_optional_op, nil, @start]
        @start = @scanner.pos
      when 42 # *
        @scanner.pos += 1
        @tokens << [:token_repeat_op, nil, @start]
        @start = @scanner.pos
      when 43 # +
        @scanner.pos += 1
        @tokens << [:token_repeat_once_op, nil, @start]
        @start = @scanner.pos
      when 123 # {
        @scanner.pos += 1
        @tokens << [:token_l_brace, nil, @start]
        @start = @scanner.pos

        loop do
          skip_trivia
          if @scanner.peek_byte == 44 # steep:ignore
            # comma
            @scanner.pos += 1
            @tokens << [:token_comma, nil, @start]
            @start = @scanner.pos
          elsif (value = @scanner.scan(RE_NUMBER))
            @tokens << [:token_comma, value, @start]
            @start = @scanner.pos
          else
            break
          end
        end

        skip_trivia
        raise "expected a closing brace" unless @scanner.scan_byte == 125
      end
    end

    def accept_string_literal?
      return false unless @scanner.peek_byte == 34 # steep:ignore

      # Move past opening quote
      @scanner.pos += 1
      @start = @scanner.pos
      kind = :token_string

      loop do
        case @scanner.scan_byte
        when 92 # \
          @scanner.scan_byte
          kind = :token_string_esc
        when nil
          raise "unclosed string starting at index #{@start}"
        when 34 # "
          value = @grammar.byteslice(@start...(@scanner.pos - 1)) || raise
          @tokens << [kind, value, @start]
          @start = @scanner.pos
          return true
        end
      end
    end

    def accept_ci_string_literal?
      return false unless @scanner.peek_byte == 94 # steep:ignore

      # Skip '^'
      @scanner.pos += 1
      @start = @scanner.pos

      raise "expected a string literal" unless @scanner.scan_byte == 34 # "

      # Move past opening quote
      @start = @scanner.pos
      kind = :token_ci_string

      loop do
        case @scanner.scan_byte
        when 92 # \
          @scanner.scan_byte
          kind = :token_ci_string_esc
        when nil
          raise "unclosed string starting at index #{@start}"
        when 34 # "
          value = @grammar.byteslice(@start...(@scanner.pos - 1)) || raise
          @tokens << [kind, value, @start]
          @start = @scanner.pos
          return true
        end
      end
    end
  end
end
