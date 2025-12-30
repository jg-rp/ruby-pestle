# frozen_string_literal: true

# These tests are translated from Rust pest's `reporting.rs`.
#
# https://github.com/pest-parser/pest/blob/master/derive/tests/reporting.rs
#
# See LICENSE_PEST.txt

require "pathname"
require "test_helper"

class TestReporting < Minitest::Test
  make_my_diffs_pretty!

  GRAMMAR = Pathname.new("test/grammars/reporting.pest")
  PARSER = Pestle::Parser.from_grammar(GRAMMAR.read)

  def test_choices
    err = assert_raises(Pestle::PestParsingError) { PARSER.parse("choices", "x") }

    assert_equal(%w[a b c], err.state.furthest_expected.keys)
    assert_empty(err.state.furthest_unexpected)
    assert_equal(0, err.state.furthest_pos)
  end

  def test_choice_no_progress
    err = assert_raises(Pestle::PestParsingError) { PARSER.parse("choices_no_progress", "x") }

    assert_equal(%w[a b c], err.state.furthest_expected.keys)
    assert_empty(err.state.furthest_unexpected)
    assert_equal(0, err.state.furthest_pos)
  end

  def test_choice_a_progress
    err = assert_raises(Pestle::PestParsingError) { PARSER.parse("choices_a_progress", "a") }

    assert_equal(%w[a], err.state.furthest_expected.keys)
    assert_empty(err.state.furthest_unexpected)
    assert_equal(1, err.state.furthest_pos)
  end

  def test_choice_b_progress
    err = assert_raises(Pestle::PestParsingError) { PARSER.parse("choices_b_progress", "b") }

    assert_equal(%w[b], err.state.furthest_expected.keys)
    assert_empty(err.state.furthest_unexpected)
    assert_equal(1, err.state.furthest_pos)
  end

  def test_nested
    err = assert_raises(Pestle::PestParsingError) { PARSER.parse("level1", "x") }

    assert_equal(%w[a b c], err.state.furthest_expected.keys)
    assert_empty(err.state.furthest_unexpected)
    assert_equal(0, err.state.furthest_pos)
  end

  def test_negative
    err = assert_raises(Pestle::PestParsingError) { PARSER.parse("negative", "x") }

    assert_empty(err.state.furthest_expected)
    assert_equal(%w[d], err.state.furthest_unexpected.keys)
    assert_equal(0, err.state.furthest_pos)
  end

  def test_negative_match
    err = assert_raises(Pestle::PestParsingError) { PARSER.parse("negative_match", "x") }

    assert_equal(%w[b], err.state.furthest_expected.keys)
    assert_empty(err.state.furthest_unexpected)
    assert_equal(0, err.state.furthest_pos)
  end

  def test_mixed
    err = assert_raises(Pestle::PestParsingError) { PARSER.parse("mixed", "x") }

    assert_equal(%w[a], err.state.furthest_expected.keys)
    assert_equal(%w[d], err.state.furthest_unexpected.keys)
    assert_equal(0, err.state.furthest_pos)
  end

  def test_mixed_progress
    err = assert_raises(Pestle::PestParsingError) { PARSER.parse("mixed_progress", "b") }

    assert_equal(%w[a], err.state.furthest_expected.keys)
    assert_empty(err.state.furthest_unexpected)
    assert_equal(1, err.state.furthest_pos)
  end
end
