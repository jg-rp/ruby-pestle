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

module PrattExample
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

  # Example Pratt parser for a calculator grammar.
  class CalculatorParser < Pestle::PrattParser
    PREFIX_OPS = { neg: 6 }.freeze

    INFIX_OPS = {
      add: [3, LEFT_ASSOC],
      sub: [3, LEFT_ASSOC],
      mul: [4, LEFT_ASSOC],
      div: [4, LEFT_ASSOC],
      pow: [5, RIGHT_ASSOC]
    }.freeze

    POSTFIX_OPS = { fac: 7 }.freeze

    def parse(program)
      pairs = PARSER.parse(START_RULE, program)
      parse_expr(pairs.first.inner.first.stream)
    end

    def parse_primary(pair)
      case pair
      in :int, _
        IntExpr.new(pair.text.to_i)
      in :ident, _
        VarExpr.new(pair.text)
      in :expr, _
        parse_expr(pair.stream)
      else
        raise "unexpected #{pair.text.inspect}"
      end
    end

    def parse_prefix(op, rhs)
      raise "unknown prefix operator #{op.text.inspect}" unless op.rule == :neg

      PrefixExpr.new(:-@, rhs)
    end

    def parse_postfix(lhs, op)
      raise "unknown postfix operator #{op.text.inspect}" unless op.rule == :fac

      PostfixExpr.new(lhs, :fact)
    end

    def parse_infix(lhs, op, rhs)
      case op
      in :add, _
        InfixExpr.new(lhs, :+, rhs)
      in :sub, _
        InfixExpr.new(lhs, :-, rhs)
      in :mul, _
        InfixExpr.new(lhs, :*, rhs)
      in :div, _
        InfixExpr.new(lhs, :/, rhs)
      in :pow, _
        InfixExpr.new(lhs, :**, rhs)
      else
        raise "unknown infix operator #{op.text.inspect}"
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  parser = PrattExample::CalculatorParser.new
  prog = parser.parse("1 + 2 + x")
  puts prog.evaluate({ "x" => 39 })
end
