# frozen_string_literal: true

require_relative "../examples/calculator_prec_climber"

class TestCalculatorExample < Minitest::Test
  def eval_expr(expr, data)
    prog = parse_program(expr)
    prog.evaluate(data)
  end

  def test_simple_literals
    assert_equal(0, eval_expr("0", {}))
    assert_equal(42, eval_expr("42", {}))
    assert_equal(123, eval_expr("123", {}))
  end

  def test_basic_arithmetic
    assert_equal(3, eval_expr("1 + 2", {}))
    assert_equal(4, eval_expr("7 - 3", {}))
    assert_equal(10, eval_expr("2 * 3 + 4", {}))
    assert_equal(14, eval_expr("2 + 3 * 4", {}))
    assert_equal(5, eval_expr("10 / 2", {}))
    assert_equal(9, eval_expr("(1 + 2) * 3", {}))
    assert_equal(7, eval_expr("1 + 2 * 3", {}))
  end

  def test_prefix_and_postfix
    assert_equal(-5, eval_expr("-5", {}))
    assert_equal(5, eval_expr("--5", {}))
    assert_equal(120, eval_expr("5!", {}))
    assert_equal(720, eval_expr("3!!", {}))
    assert_equal(-6, eval_expr("-(3!)", {}))
  end

  def test_exponentiation_and_precedence
    assert_equal(8, eval_expr("2 ^ 3", {}))
    assert_equal(512, eval_expr("2 ^ 3 ^ 2", {}))
    assert_equal(18, eval_expr("2 * 3 ^ 2", {}))
  end

  def test_variables_and_factorials
    assert_equal(5, eval_expr("x + y", { "x" => 2, "y" => 3 }))
    assert_equal(7, eval_expr("x * y + 1", { "x" => 2, "y" => 3 }))
    assert_equal(9, eval_expr("(x + 1) * y", { "x" => 2, "y" => 3 }))
    assert_equal(24, eval_expr("n!", { "n" => 4 }))
    assert_equal(720, eval_expr("n!!", { "n" => 3 }))
  end

  def test_error_conditions
    assert_raises(Pestle::PestParsingError) { eval_expr("1 +", {}) }
    assert_raises(Pestle::PestParsingError) { eval_expr("1 + * 2", {}) }
  end
end
