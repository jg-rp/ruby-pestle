# frozen_string_literal: true

require_relative "../examples/calculator_prec_climber"
require_relative "../examples/calculator_pratt"

class TestCalculatorExample < Minitest::Test
  PRATT_PARSER = PrattExample::CalculatorParser.new

  def assert_expr(expr, data, want)
    prog = PrecClimberExample.parse_program(expr)

    assert_equal(want, prog.evaluate(data))

    prog = PRATT_PARSER.parse(expr)

    assert_equal(want, prog.evaluate(data))
  end

  def test_simple_literals
    assert_expr("0", {}, 0)
    assert_expr("42", {}, 42)
    assert_expr("123", {}, 123)
  end

  def test_basic_arithmetic
    assert_expr("1 + 2", {}, 3)
    assert_expr("7 - 3", {}, 4)
    assert_expr("2 * 3 + 4", {}, 10)
    assert_expr("2 + 3 * 4", {}, 14)
    assert_expr("10 / 2", {}, 5)
    assert_expr("(1 + 2) * 3", {}, 9)
    assert_expr("1 + 2 * 3", {}, 7)
  end

  def test_prefix_and_postfix
    assert_expr("-5", {}, -5)
    assert_expr("--5", {}, 5)
    assert_expr("5!", {}, 120)
    assert_expr("3!!", {}, 720)
    assert_expr("-(3!)", {}, -6)
  end

  def test_exponentiation_and_precedence
    assert_expr("2 ^ 3", {}, 8)
    assert_expr("2 ^ 3 ^ 2", {}, 512)
    assert_expr("2 * 3 ^ 2", {}, 18)
  end

  def test_variables_and_factorials
    assert_expr("x + y", { "x" => 2, "y" => 3 }, 5)
    assert_expr("x * y + 1", { "x" => 2, "y" => 3 }, 7)
    assert_expr("(x + 1) * y", { "x" => 2, "y" => 3 }, 9)
    assert_expr("n!", { "n" => 4 }, 24)
    assert_expr("n!!", { "n" => 3 }, 720)
  end
end
