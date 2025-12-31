# frozen_string_literal: true

module Pestle
  # A Generic Pratt parser base class operating on a Pestle::Stream of token pairs.
  class PrattParser
    # A mapping of prefix operator rule symbols to precedence levels.
    PREFIX_OPS = {} # : Hash[Symbol, Integer]

    # A mapping of infix operator rule symbols to [precedence, right_associative].
    INFIX_OPS = {} # : Hash[Symbol, [Integer, bool]]

    # A mapping of postfix operator rule symbols to precedence levels.
    POSTFIX_OPS = {} # : Hash[Symbol, Integer]

    LEFT_ASSOC = false
    RIGHT_ASSOC = true

    def parse_primary(pair) # rubocop: disable Lint/UnusedMethodArgument
      raise "parsers must implement `parse_primary: (Pair pair) -> Expr`"
    end

    def parse_prefix(op, rhs) # rubocop: disable Lint/UnusedMethodArgument
      raise "parsers must implement `parse_prefix: (Pair op, Expr rhs) -> Expr`"
    end

    def parse_infix(lhs, op, rhs) # rubocop: disable Lint/UnusedMethodArgument
      raise "parsers must implement `parse_infix: (Expr lhs, Pair op, Expr rhs) -> Expr`"
    end

    def parse_postfix(lhs, op) # rubocop: disable Lint/UnusedMethodArgument
      raise "parsers must implement `parse_postfix: (Expr lhs, Pair op) -> Expr`"
    end

    def parse_expr(stream, min_prec = 0)
      token = stream.next
      raise "unexpected end of expression" if token.nil? # TODO: SyntaxError.new

      # Handle prefix operators or primary expression
      left = if self.class::PREFIX_OPS.include?(token.rule)
               prec = self.class::PREFIX_OPS[token.rule] || raise
               rhs = parse_expr(stream, prec)
               parse_prefix(token, rhs)
             else
               parse_primary(token)
             end

      # Handle infix and postfix operators
      loop do
        next_token = stream.peek
        break if next_token.nil?

        if self.class::POSTFIX_OPS.include?(next_token.rule)
          stream.next
          left = parse_postfix(left, next_token)
          next
        end

        if self.class::INFIX_OPS.include?(next_token.rule)
          prec, right_assoc = self.class::INFIX_OPS[next_token.rule]
          break if prec.nil? || prec < min_prec

          stream.next
          rhs = parse_expr(stream, prec + (right_assoc ? 0 : 1))
          left = parse_infix(left, next_token, rhs || raise)
          next
        end

        break
      end

      left
    end
  end
end
