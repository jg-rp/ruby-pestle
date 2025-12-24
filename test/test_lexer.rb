# frozen_string_literal: true

require "test_helper"

class TestTokenize < Minitest::Spec
  make_my_diffs_pretty!

  def assert_tokens(tokens, expect)
    assert_equal(tokens.length, expect.length)
    tokens.zip(expect).each do |got, want|
      assert_equal(got[0..1], want)
    end
  end

  def test_string
    grammar = 'string = { "abc" }'
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "string"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_string, "abc"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_insensitive
    grammar = 'insensitive = { ^"abc" }'
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "insensitive"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ci_string, "abc"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_range
    grammar = "range = { '0'..'9' }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "range"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_char, "0"],
      [:token_range_op, nil],
      [:token_char, "9"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_ident
    grammar = "ident = { string }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "ident"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_pos_pred
    grammar = "pos_pred = { &string }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "pos_pred"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_pos_pred, nil],
      [:token_ident, "string"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_neg_pred
    grammar = "neg_pred = { !string }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "neg_pred"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_neg_pred, nil],
      [:token_ident, "string"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_double_neg_pred
    grammar = "double_neg_pred = { !!string }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "double_neg_pred"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_neg_pred, nil],
      [:token_neg_pred, nil],
      [:token_ident, "string"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_sequence
    grammar = "sequence = { string ~ string }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "sequence"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_sequence_op, nil],
      [:token_ident, "string"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_sequence_non_atomic
    grammar = "sequence = !{ string ~ string }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "sequence"],
      [:token_assign_op, nil],
      [:token_mod_non_atomic, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_sequence_op, nil],
      [:token_ident, "string"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_sequence_compound
    grammar = "sequence = ${ string ~ string }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "sequence"],
      [:token_assign_op, nil],
      [:token_mod_compound, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_sequence_op, nil],
      [:token_ident, "string"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_sequence_atomic
    grammar = "sequence = @{ string ~ string }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "sequence"],
      [:token_assign_op, nil],
      [:token_mod_atomic, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_sequence_op, nil],
      [:token_ident, "string"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_silent
    grammar = 'WHITESPACE = _{ " " }'
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "WHITESPACE"],
      [:token_assign_op, nil],
      [:token_mod_silent, nil],
      [:token_l_brace, nil],
      [:token_string, " "],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end
end
