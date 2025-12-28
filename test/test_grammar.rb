# frozen_string_literal: true

# These tests are translated from Rust pest's `grammars.rs`.
#
# https://github.com/pest-parser/pest/blob/master/vm/tests/grammar.rs.
#
# See LICENSE_PEST.txt

require "pathname"
require "test_helper"

class TestGrammar < Minitest::Spec
  make_my_diffs_pretty!

  GRAMMAR = Pathname.new("test/grammars/grammar.pest")
  PARSER = Pestle::Parser.from_grammar(GRAMMAR.read)

  def test_string
    want = [
      {
        "rule" => "string",
        "span" => { "str" => "abc", "start" => 0, "end" => 3 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("string", "abc").dump)
  end

  def test_insensitive
    want = [
      {
        "rule" => "insensitive",
        "span" => { "str" => "aBC", "start" => 0, "end" => 3 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("insensitive", "aBC").dump)
  end

  def test_range
    want = [
      {
        "rule" => "range",
        "span" => { "str" => "6", "start" => 0, "end" => 1 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("range", "6").dump)
  end

  def test_ident
    want = [
      {
        "rule" => "ident",
        "span" => { "str" => "abc", "start" => 0, "end" => 3 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("ident", "abc").dump)
  end

  def test_pos_pred
    want = [
      {
        "rule" => "pos_pred",
        "span" => { "str" => "", "start" => 0, "end" => 0 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("pos_pred", "abc").dump)
  end

  def test_neg_pred
    want = [
      {
        "rule" => "neg_pred",
        "span" => { "str" => "", "start" => 0, "end" => 0 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("neg_pred", "").dump)
  end

  def test_double_neg_pred
    want = [
      {
        "rule" => "double_neg_pred",
        "span" => { "str" => "", "start" => 0, "end" => 0 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("double_neg_pred", "abc").dump)
  end

  def test_sequence
    want = [
      {
        "rule" => "sequence",
        "span" => { "str" => "abc   abc", "start" => 0, "end" => 9 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 6, "end" => 9 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("sequence", "abc   abc").dump)
  end

  # TODO: sequence_compound
end
