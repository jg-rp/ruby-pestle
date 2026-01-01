# frozen_string_literal: true

require_relative "errors"
require_relative "expression"
require_relative "expressions/choice"
require_relative "expressions/group"
require_relative "expressions/identifier"
require_relative "expressions/postfix"
require_relative "expressions/prefix"
require_relative "expressions/range"
require_relative "expressions/sequence"
require_relative "expressions/stack"
require_relative "expressions/string"
require_relative "rule"

module Pestle::Grammar
  # Pest grammar parser.
  class Parser
    PREC_LOWEST = 1
    PREC_CHOICE = 2
    PREC_SEQUENCE = 3
    PREC_PREFIX = 4

    PRECEDENCES = {
      token_choice_op: PREC_CHOICE,
      token_sequence_op: PREC_SEQUENCE
    }.freeze

    INFIX_OPERATORS = Set.new(%i[token_choice_op token_sequence_op])

    def initialize(source, tokens)
      @source = source
      @tokens = tokens
      @pos = 0
      @eof = tokens.last || raise
    end

    # Return the current token without consuming it.
    # An EOF token is returned if there are no tokens left.
    def current = @tokens[@pos] || @eof

    # Consume and return the current token.
    def next
      token = @tokens[@pos]
      @pos += 1 unless token.nil?
      token || @eof
    end

    # Peek ahead without consuming tokens.
    def peek(offset = 1) = @tokens[@pos + offset] || @eof

    # Consume the next token if its kind matches _kind_, raise an error if it does not.
    def eat(kind, message = nil)
      token = self.next

      unless token.first == kind
        raise PestGrammarError.new(message || "unexpected #{token.first}", @source, token)
      end

      token
    end

    def parse
      grammar_doc = [] # : Array[String]
      grammar_doc << (self.next[1] || raise) while current.first == :token_grammar_doc
      [parse_rules, grammar_doc.join("\n")]
    end

    def parse_rules
      rules = {} # : Hash[String, Rule]

      loop do
        break if current.first == :token_eof

        rule_doc = [] # : Array[String]
        rule_doc << (self.next[1] || raise) while current.first == :token_rule_doc
        name = eat(:token_ident)[1] || raise
        eat(:token_assign_op)
        modifier = parse_modifier
        eat(:token_l_brace)
        expression = parse_expression(PREC_LOWEST)
        eat(:token_r_brace)

        rules[name] = Rule.new(name, expression, modifier: modifier, doc: rule_doc.join("\n"))
      end

      rules
    end

    def parse_modifier
      case current.first
      when :token_mod_silent
        @pos += 1
        1 << 0
      when :token_mod_atomic
        @pos += 1
        1 << 1
      when :token_mod_compound
        @pos += 1
        1 << 2
      when :token_mod_non_atomic
        @pos += 1
        1 << 3
      else
        0
      end
    end

    def parse_expression(precedence)
      # Skip leading choice operator
      self.next if current.first == :token_choice_op

      tag = if current.first == :token_tag
              tag_tok = self.next
              eat(:token_assign_op)
              tag_tok[1]
            end

      token = current

      # @type var left: Expression
      left = case token.first
             when :token_string
               StringLiteral.new(self.next[1] || raise, tag: tag)
             when :token_ci_string
               InsensitiveString.new(self.next[1] || raise, tag: tag)
             when :token_string_esc
               StringLiteral.new(unescape(self.next[1] || raise, token),
                                 tag: tag)
             when :token_ci_string_esc
               InsensitiveString.new(unescape(self.next[1] || raise, token),
                                     tag: tag)
             when :token_l_paren
               @pos += 1
               expr = Group.new(parse_expression(PREC_LOWEST), tag: tag)
               eat(:token_r_paren)
               expr
             when :token_ident
               Identifier.new(self.next[1] || raise, tag: tag)
             when :token_push_literal
               @pos += 1
               PushLiteral.new(eat(:token_string)[1] || raise, tag: tag)
             when :token_push_expr
               @pos += 1
               eat(:token_l_paren)
               expr = Push.new(parse_expression(PREC_LOWEST), tag: tag)
               eat(:token_r_paren)
               expr
             when :token_peek
               @pos += 1
               parse_peek_expression(tag)
             when :token_peek_all
               @pos += 1
               PeekAll.new(tag: tag)
             when :token_pop
               @pos += 1
               Pop.new(tag: tag)
             when :token_drop
               @pos += 1
               Drop.new(tag: tag)
             when :token_pop_all
               @pos += 1
               PopAll.new(tag: tag)
             when :token_char
               start = unescape(self.next[1] || raise, token)
               eat(:token_range_op)
               stop = unescape(eat(:token_char)[1] || raise, token)
               Range.new(start, stop, tag: tag)
             when :token_pos_pred
               @pos += 1
               PositivePredicate.new(parse_expression(PREC_PREFIX), tag: tag)
             when :token_neg_pred
               @pos += 1
               NegativePredicate.new(parse_expression(PREC_PREFIX), tag: tag)
             else
               raise PestGrammarError.new("unexpected token #{token.first}", @source, token)
             end

      left = parse_postfix_expression(left)

      loop do
        kind = current.first
        break unless INFIX_OPERATORS.member?(kind)
        break if (PRECEDENCES[kind] || PREC_LOWEST) < precedence

        left = parse_infix_expression(left)
      end

      left
    end

    def parse_infix_expression(left)
      token = self.next
      kind = token.first
      precedence = PRECEDENCES[kind] || PREC_LOWEST
      right = parse_expression(precedence)

      case kind
      when :token_choice_op
        if right.is_a?(Choice)
          Choice.new(left, *right.children)
        else
          Choice.new(left, right)
        end
      when :token_sequence_op
        if right.is_a?(Sequence)
          Sequence.new(left, *right.children)
        else
          Sequence.new(left, right)
        end
      else
        raise PestGrammarError.new("unexpected operator #{kind}", @source, token)
      end
    end

    def parse_postfix_expression(expr)
      token = current
      kind = token.first

      case kind
      when :token_optional_op
        @pos += 1
        Optional.new(expr)
      when :token_repeat_op
        @pos += 1
        Repeat.new(expr)
      when :token_repeat_once_op
        @pos += 1
        RepeatOnce.new(expr)
      when :token_l_brace
        @pos += 1
        parse_repeat_expression(expr)
      else
        expr
      end
    end

    def parse_repeat_expression(expr)
      token = self.next
      kind = token.first

      if kind == :token_number
        number = (token[1] || raise).to_i
        if current.first == :token_r_brace
          @pos += 1
          return RepeatExact.new(expr, number)
        end

        eat(:token_comma)

        if current.first == :token_r_brace
          @pos += 1
          return RepeatMin.new(expr, number)
        end

        stop = (eat(:token_number)[1] || raise).to_i
        eat(:token_r_brace)
        return RepeatMinMax.new(expr, number, stop)
      end

      if kind == :token_comma
        number = (eat(:token_number)[1] || raise).to_i
        eat(:token_r_brace)
        return RepeatMax.new(expr, number)
      end

      raise PestGrammarError.new("expected a number or a comma", @source, token)
    end

    def parse_peek_expression(tag)
      return Peek.new(tag: tag) unless current.first == :token_l_bracket

      self.next
      start = ((self.next[1] || raise).to_i if current.first == :token_integer)
      eat(:token_range_op)
      stop = ((self.next[1] || raise).to_i if current.first == :token_integer)
      eat(:token_r_bracket)
      PeekSlice.new(start, stop, tag: tag)
    end

    RE_SLASH_X = /\\x([0-9a-fA-F]{2})/
    RE_SLASH_U = /\\u\{([0-9a-fA-F]{2,6})\}/

    def unescape(value, token)
      unescaped = [] # : Array[String]
      scanner = StringScanner.new(value)

      until scanner.eos?
        if scanner.scan(RE_SLASH_X)
          unescaped << (scanner.captures&.first || raise).to_i(16).chr(Encoding::UTF_8)
          next
        end

        if scanner.scan(RE_SLASH_U)
          unescaped << (scanner.captures&.first || raise).to_i(16).chr(Encoding::UTF_8)
          next
        end

        ch = scanner.getch

        break if ch.nil?

        unless ch == "\\"
          unescaped << ch
          next
        end

        ch = scanner.getch

        case ch
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
        when nil
          raise PestGrammarError.new("incomplete escape sequence", @source, token)
        else
          raise PestGrammarError.new("unknown escape sequence", @source, token)
        end
      end

      unescaped.join
    end
  end
end
