# frozen_string_literal: true

# Based on the calculator example found in the pest book, with
# the addition of the `ident` rule.
# https://pest.rs/book/precedence.html.

# https://github.com/pest-parser/book/blob/master/LICENSE-MIT
#
# Permission is hereby granted, free of charge, to any
# person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the
# Software without restriction, including without
# limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
# ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
# SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

require_relative "../lib/pestle"

module PrecClimberExample
  GRAMMAR = <<~'GRAMMAR'
    WHITESPACE   =  _{ " " | "\t" | NEWLINE }

    program      =   { SOI ~ expr ~ EOI }
      expr       =   { prefix* ~ primary ~ postfix* ~ (infix ~ prefix* ~ primary ~ postfix* )* }
        infix    =  _{ add | sub | mul | div | pow }
          add    =   { "+" } // Addition
          sub    =   { "-" } // Subtraction
          mul    =   { "*" } // Multiplication
          div    =   { "/" } // Division
          pow    =   { "^" } // Exponentiation
        prefix   =  _{ neg }
          neg    =   { "-" } // Negation
        postfix  =  _{ fac }
          fac    =   { "!" } // Factorial
        primary  =  _{ int | "(" ~ expr ~ ")" | ident }
          int    =  @{ (ASCII_NONZERO_DIGIT ~ ASCII_DIGIT+ | ASCII_DIGIT) }
          ident  =  @{ ASCII_ALPHA+ }
  GRAMMAR

  PARSER = Pestle::Parser.from_grammar(GRAMMAR)

  START_RULE = :program

  # Very basic abstract syntax tree (AST) nodes.

  VarExpr = Struct.new(:value) do
    def evaluate(vars) = vars[value]
  end

  IntExpr = Struct.new(:value) do
    def evaluate(vars) = value # rubocop: disable Lint/UnusedMethodArgument
  end

  PrefixExpr = Struct.new(:op, :expr) do
    def evaluate(vars) = expr.evaluate(vars).send(op)
  end

  InfixExpr = Struct.new(:left, :op, :right) do
    def evaluate(vars) = left.evaluate(vars).send(op, right.evaluate(vars))
  end

  PostfixExpr = Struct.new(:expr, :op) do
    def evaluate(vars) = expr.evaluate(vars).send(op)
  end

  # Monkey patch Integer with a factorial method.
  class ::Integer
    remove_method(:fact) if method_defined?(:fact)
    def fact
      (1..self).reduce(1, :*)
    end
  end

  # Operator precedence
  PREC_LOWEST = 1
  PREC_ADD = 3
  PREC_SUB = 3
  PREC_MUL = 4
  PREC_DIV = 4
  PREC_POW = 5
  PREC_FAC = 7
  PREC_PRE = 8

  PRECEDENCES = {
    add: PREC_ADD,
    sub: PREC_SUB,
    mul: PREC_MUL,
    div: PREC_DIV,
    pow: PREC_POW,
    fac: PREC_FAC
  }.freeze

  INFIX_OPS = Set.new(%i[add sub mul div pow]).freeze

  PREFIX_OPS = Set.new(%i[neg]).freeze

  POSTFIX_OPS = Set.new(%i[fac]).freeze

  # Calculator expression parser entry point.
  # @param text [String]
  # @return [Expr] A tree structure built from expression structs defined above.
  def self.parse_program(text)
    program = PARSER.parse(START_RULE, text)

    # A successful parse is guaranteed to give us a root "program" pair with a
    # single child. Unwrap it and get it's children as a Pestle::Pairs instance.
    pairs = program.first.inner

    # For this grammar, the `program` token is guaranteed to have exactly two
    # children, an `expr` and `EOI`. Turn the expression into a stream and
    # pass it to `parse_expr`.
    parse_expr(pairs.first.stream)
  end

  # @param pairs [Pestle::Stream]
  # @param precedence [Integer]
  def self.parse_expr(pairs, precedence = PREC_LOWEST)
    pair = pairs.next
    raise "unexpected end of expression" if pair.nil?

    left = if PREFIX_OPS.include?(pair.rule)
             parse_prefix_expr(pair, pairs)
           else
             parse_basic_expr(pair)
           end

    pair = pairs.next

    # Handle infix operators.
    while !pair.nil? && INFIX_OPS.include?(pair.rule)
      if (PRECEDENCES[pair.rule] || PREC_LOWEST) >= precedence
        left = parse_infix_expr(pair, pairs, left)
        pair = pairs.next
      else
        pairs.backup
        return left
      end
    end

    # Handle postfix operators
    while !pair.nil? && POSTFIX_OPS.include?(pair.rule)
      left = parse_postfix_expr(pair, left)
      pair = pairs.next
    end

    raise "unexpected #{pair.text.inspect}" unless pair.nil? || pair.rule == :EOI

    left
  end

  # @param pair [Pestle::Pair]
  # @param pairs [Pestle::Stream]
  def self.parse_prefix_expr(pair, pairs)
    raise "unknown prefix operator #{pair.text.inspect}" unless PREFIX_OPS.include?(pair.rule)

    PrefixExpr.new(:-@, parse_expr(pairs, PREC_PRE))
  end

  # @param op [Pestle::Pair]
  # @param pairs [Pestle::Stream]
  # @param left [Pestle::Pair]
  def self.parse_infix_expr(op, pairs, left)
    precedence = PRECEDENCES[op.rule] || PREC_LOWEST
    right = parse_expr(pairs, precedence)

    case op
    in :add, _
      InfixExpr.new(left, :+, right)
    in :sub, _
      InfixExpr.new(left, :-, right)
    in :mul, _
      InfixExpr.new(left, :*, right)
    in :div, _
      InfixExpr.new(left, :/, right)
    in :pow, _
      InfixExpr.new(left, :**, right)
    else
      raise "unknown infix operator #{op.text.inspect}"
    end
  end

  # @param op [Pestle::Pair]
  # @param left [Pestle::Pair]
  def self.parse_postfix_expr(op, left)
    raise "unknown postfix operator #{op.text.inspect}" unless POSTFIX_OPS.include?(op.rule)

    PostfixExpr.new(left, :fact)
  end

  # @param pair [Pestle::Pair]
  def self.parse_basic_expr(pair)
    case pair
    in :int, _
      IntExpr.new(pair.text.to_i)
    in :ident, _
      VarExpr.new(pair.text)
    in :expr, _
      parse_expr(pair.inner.stream)
    else
      raise "unexpected #{pair.text.inspect}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  prog = PrecClimberExample.parse_program("1 + 2 + x")
  puts prog.evaluate({ "x" => 39 })
end
