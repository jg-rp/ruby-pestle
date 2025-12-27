# frozen_string_literal: true

require_relative "errors"
require_relative "expression"
require_relative "expressions/choice"
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

    def initialize(tokens)
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
        raise PestParsingError.new(message || "unexpected #{token.first}", token)
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
      when :token_mod_nonatomic
        @pos += 1
        1 << 3
      else
        0
      end
    end

    def parse_expression(precedence)
      # Skip leading choice operator
      self.next if current.first == :token_choice_op

      tag = (self.next[1] if current.first == :token_tag)
      token = current

      # @type var left: Expression
      left = case token.first
             when :token_string
               StringLiteral.new(self.next[1] || raise)
             when :token_ci_string
               InsensitiveString.new(self.next[1] || raise)
             when :token_string_esc
               StringLiteral.new(unescape(self.next[1] || raise))
             when :token_ci_string_esc
               InsensitiveString.new(unescape(self.next[1] || raise))
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
             when :token_push
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
               start = unescape_char(self.next[1] || raise)
               eat(:token_range_op)
               stop = unescape_char(eat(:token_char)[1] || raise)
               Range.new(start, stop, tag: tag)
             when :token_pos_pred
               @pos += 1
               PositivePredicate.new(parse_expression(PREC_PREFIX), tag: tag)
             when :token_neg_pred
               @pos += 1
               NegativePredicate.new(parse_expression(PREC_PREFIX), tag: tag)
             else
               raise PestParsingError.new("unexpected token #{token.first}", token)
             end

      left = parse_postfix_expression(left)

      loop do
        kind = current.first
        prec = PRECEDENCES[kind]
        break if kind == :token_eof || prec.nil? || prec < precedence

        left = parse_infix_expression(left)
      end

      left
    end

    def parse_infix_expression(left)
      # TODO:
      raise "not implemented"
    end

    def parse_postfix_expression(expr)
      # TODO:
      raise "not implemented"
    end

    def parse_peek_expression(tag)
      # TODO:
      raise "not implemented"
    end
  end
end
