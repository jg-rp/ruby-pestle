# frozen_string_literal: true

# These tests are derived from Rust pest's `grammars.rs`.
#
# https://github.com/pest-parser/pest/blob/master/vm/tests/grammar.rs.
#
# See LICENSE_PEST.txt

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

  def test_node_tag
    grammar = "node_tag = { #string = string }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "node_tag"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_tag, "string"],
      [:token_assign_op, nil],
      [:token_ident, "string"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_choice
    grammar = "choice = { string | range }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "choice"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_choice_op, nil],
      [:token_ident, "range"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_choice_prefix
    grammar = "choice = { | string | range }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "choice"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_choice_op, nil],
      [:token_ident, "range"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_optional
    grammar = "optional = { string? }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "optional"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_optional_op, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_repeat
    grammar = "repeat = { string* }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "repeat"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_repeat_op, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_repeat_once
    grammar = "repeat_once = { string+ }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "repeat_once"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_repeat_once_op, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_repeat_min_max
    grammar = "repeat_min_max = { string{2, 3} }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "repeat_min_max"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_l_brace, nil],
      [:token_number, "2"],
      [:token_comma, nil],
      [:token_number, "3"],
      [:token_r_brace, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_repeat_exact
    grammar = "repeat_exact = { string{2} }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "repeat_exact"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_l_brace, nil],
      [:token_number, "2"],
      [:token_r_brace, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_repeat_min
    grammar = "repeat_min = { string{2,} }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "repeat_min"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_l_brace, nil],
      [:token_number, "2"],
      [:token_comma, nil],
      [:token_r_brace, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_repeat_max
    grammar = "repeat_max = { string{, 2} }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "repeat_max"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "string"],
      [:token_l_brace, nil],
      [:token_comma, nil],
      [:token_number, "2"],
      [:token_r_brace, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_soi_at_start
    grammar = "soi_at_start = { SOI ~ string }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "soi_at_start"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_ident, "SOI"],
      [:token_sequence_op, nil],
      [:token_ident, "string"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_push_pop
    grammar = "repeat_mutate_stack = { (PUSH('a'..'c') ~ \",\")* ~ POP ~ POP ~ POP }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "repeat_mutate_stack"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_l_paren, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_char, "a"],
      [:token_range_op, nil],
      [:token_char, "c"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_string, ","],
      [:token_r_paren, nil],
      [:token_repeat_op, nil],
      [:token_sequence_op, nil],
      [:token_pop, nil],
      [:token_sequence_op, nil],
      [:token_pop, nil],
      [:token_sequence_op, nil],
      [:token_pop, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_push_pop_all
    grammar = "repeat_mutate_stack_pop_all = { (PUSH('a'..'c') ~ \",\")* ~ POP_ALL }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "repeat_mutate_stack_pop_all"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_l_paren, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_char, "a"],
      [:token_range_op, nil],
      [:token_char, "c"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_string, ","],
      [:token_r_paren, nil],
      [:token_repeat_op, nil],
      [:token_sequence_op, nil],
      [:token_pop_all, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_peek
    grammar = "peek = { PUSH(range) ~ PUSH(range) ~ PEEK ~ PEEK }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "peek"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_ident, "range"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_ident, "range"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_peek, nil],
      [:token_sequence_op, nil],
      [:token_peek, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_peek_all
    grammar = "peek_all = { PUSH(range) ~ PUSH(range) ~ PEEK_ALL }"
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "peek_all"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_ident, "range"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_ident, "range"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_peek_all, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_peek_range
    # rubocop: disable Layout/LineLength
    grammar = "peek_slice_23 = { PUSH(range) ~ PUSH(range) ~ PUSH(range) ~ PUSH(range) ~ PUSH(range) ~ PEEK[1..-2] }"
    # rubocop: enable Layout/LineLength

    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_ident, "peek_slice_23"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_ident, "range"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_ident, "range"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_ident, "range"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_ident, "range"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_push_expr, nil],
      [:token_l_paren, nil],
      [:token_ident, "range"],
      [:token_r_paren, nil],
      [:token_sequence_op, nil],
      [:token_peek, nil],
      [:token_l_bracket, nil],
      [:token_integer, "1"],
      [:token_range_op, nil],
      [:token_integer, "-2"],
      [:token_r_bracket, nil],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_grammar_doc
    grammar = <<~GRAMMAR
      // pest. The Elegant Parser
      //! Pest meta-grammar
      //!
      //! # Warning: Semantic Versioning
      string = { "abc" }
    GRAMMAR

    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_grammar_doc, "Pest meta-grammar"],
      [:token_grammar_doc, ""],
      [:token_grammar_doc, "# Warning: Semantic Versioning"],
      [:token_ident, "string"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_string, "abc"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_rule_doc
    grammar = <<~GRAMMAR
      /// A very simple rule.
      string = { "abc" }
    GRAMMAR

    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_rule_doc, "A very simple rule."],
      [:token_ident, "string"],
      [:token_assign_op, nil],
      [:token_l_brace, nil],
      [:token_string, "abc"],
      [:token_r_brace, nil],
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end

  def test_line_and_block_comments
    grammar = <<~GRAMMAR
      // Line comment

      /* 1-line multiline comment */

      /*
          N-line multiline comment
      */

      /*
          // Line comment inside multiline

          /*
              (Multiline inside) multiline
          */

          Invalid segment of grammar below (repeated rule)

          WHITESPACE = _{ "hi" }
      */
    GRAMMAR

    tokens = Pestle::Grammar::Lexer.tokenize(grammar)

    expect = [
      [:token_eof, nil]
    ]

    assert_tokens(tokens, expect)
  end
end
