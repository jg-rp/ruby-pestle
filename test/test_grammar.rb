# frozen_string_literal => true

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

  def test_sequence_compound
    want = [
      {
        "rule" => "sequence_compound",
        "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 3, "end" => 6 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("sequence_compound", "abcabc").dump)
  end

  def test_sequence_atomic
    want = [
      {
        "rule" => "sequence_atomic",
        "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("sequence_atomic", "abcabc").dump)
  end

  def test_sequence_non_atomic
    want = [
      {
        "rule" => "sequence_non_atomic",
        "span" => { "str" => "abc   abc", "start" => 0, "end" => 9 },
        "inner" => [
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
      }
    ]

    assert_equal(want, PARSER.parse("sequence_non_atomic", "abc   abc").dump)
  end

  def test_atomic_space
    # TODO: => error message
    assert_raises(Pestle::PestParsingError) { PARSER.parse("sequence_atomic", "abc abc") }
  end

  def test_sequence_atomic_compound
    want = [
      {
        "rule" => "sequence_atomic_compound",
        "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
        "inner" => [
          {
            "rule" => "sequence_compound",
            "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
            "inner" => [
              {
                "rule" => "string",
                "span" => { "str" => "abc", "start" => 0, "end" => 3 },
                "inner" => []
              },
              {
                "rule" => "string",
                "span" => { "str" => "abc", "start" => 3, "end" => 6 },
                "inner" => []
              }
            ]
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("sequence_atomic_compound", "abcabc").dump)
  end

  def test_sequence_compound_nested
    want = [
      {
        "rule" => "sequence_compound_nested",
        "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
        "inner" => [
          {
            "rule" => "sequence_nested",
            "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
            "inner" => [
              {
                "rule" => "string",
                "span" => { "str" => "abc", "start" => 0, "end" => 3 },
                "inner" => []
              },
              {
                "rule" => "string",
                "span" => { "str" => "abc", "start" => 3, "end" => 6 },
                "inner" => []
              }
            ]
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("sequence_compound_nested", "abcabc").dump)
  end

  def test_compound_nested_space
    # TODO: => error message
    assert_raises(Pestle::PestParsingError) { PARSER.parse("sequence_compound_nested", "abc abc") }
  end

  def test_choice_range
    want = [
      {
        "rule" => "choice",
        "span" => { "str" => "0", "start" => 0, "end" => 1 },
        "inner" => [
          {
            "rule" => "range",
            "span" => { "str" => "0", "start" => 0, "end" => 1 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("choice", "0").dump)
  end

  def test_optional_string
    want = [
      {
        "rule" => "optional",
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

    assert_equal(want, PARSER.parse("optional", "abc").dump)
  end

  def test_optional_empty
    want = [
      { "rule" => "optional", "span" => { "str" => "", "start" => 0, "end" => 0 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("optional", "").dump)
  end

  def test_repeat_empty
    want = [
      { "rule" => "repeat", "span" => { "str" => "", "start" => 0, "end" => 0 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("repeat", "").dump)
  end

  def test_repeat_string
    want = [
      {
        "rule" => "repeat",
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

    assert_equal(want, PARSER.parse("repeat", "abc   abc").dump)
  end

  def test_repeat_atomic_empty
    want = [
      {
        "rule" => "repeat_atomic",
        "span" => { "str" => "", "start" => 0, "end" => 0 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_atomic", "").dump)
  end

  def test_repeat_atomic_string
    want = [
      {
        "rule" => "repeat_atomic",
        "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_atomic", "abcabc").dump)
  end

  def test_repeat_atomic_space
    want = [
      {
        "rule" => "repeat_atomic",
        "span" => { "str" => "abc", "start" => 0, "end" => 3 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_atomic", "abc abc").dump)
  end

  def test_repeat_once_empty
    # TODO: => error message
    assert_raises(Pestle::PestParsingError) { PARSER.parse("repeat_once", "") }
  end

  def test_repeat_once_strings
    want = [
      {
        "rule" => "repeat_once",
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

    assert_equal(want, PARSER.parse("repeat_once", "abc   abc").dump)
  end

  def test_repeat_once_atomic_empty
    # TODO: => error message
    assert_raises(Pestle::PestParsingError) { PARSER.parse("repeat_once_atomic", "") }
  end

  def test_once_atomic_strings
    want = [
      {
        "rule" => "repeat_once_atomic",
        "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_once_atomic", "abcabc").dump)
  end

  def test_repeat_once_atomic_space
    want = [
      {
        "rule" => "repeat_once_atomic",
        "span" => { "str" => "abc", "start" => 0, "end" => 3 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_once_atomic", "abc abc").dump)
  end

  def test_repeat_min_max_twice
    want = [
      {
        "rule" => "repeat_min_max",
        "span" => { "str" => "abc abc", "start" => 0, "end" => 7 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 4, "end" => 7 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("repeat_min_max", "abc abc").dump)
  end

  def test_repeat_min_max_thrice
    want = [
      {
        "rule" => "repeat_min_max",
        "span" => { "str" => "abc abc abc", "start" => 0, "end" => 11 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 4, "end" => 7 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 8, "end" => 11 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("repeat_min_max", "abc abc abc").dump)
  end

  def test_repeat_min_max_atomic_twice
    want = [
      {
        "rule" => "repeat_min_max_atomic",
        "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_min_max_atomic", "abcabc").dump)
  end

  def test_repeat_min_max_atomic_thrice
    want = [
      {
        "rule" => "repeat_min_max_atomic",
        "span" => { "str" => "abcabcabc", "start" => 0, "end" => 9 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_min_max_atomic", "abcabcabc").dump)
  end

  def test_repeat_min_max_atomic_space
    # TODO: => error message
    assert_raises(Pestle::PestParsingError) { PARSER.parse("repeat_min_max_atomic", "abc abc") }
  end

  def test_repeat_exact
    want = [
      {
        "rule" => "repeat_exact",
        "span" => { "str" => "abc abc", "start" => 0, "end" => 7 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 4, "end" => 7 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("repeat_exact", "abc abc").dump)
  end

  def test_repeat_min_once
    # TODO: => error message
    assert_raises(Pestle::PestParsingError) { PARSER.parse("repeat_min", "abc") }
  end

  def test_repeat_min_twice
    want = [
      {
        "rule" => "repeat_min",
        "span" => { "str" => "abc abc", "start" => 0, "end" => 7 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 4, "end" => 7 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("repeat_min", "abc abc").dump)
  end

  def test_repeat_min_thrice
    want = [
      {
        "rule" => "repeat_min",
        "span" => { "str" => "abc abc  abc", "start" => 0, "end" => 12 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 4, "end" => 7 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 9, "end" => 12 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("repeat_min", "abc abc  abc").dump)
  end

  def test_repeat_min_atomic_once
    # TODO: => error message
    assert_raises(Pestle::PestParsingError) { PARSER.parse("repeat_min_atomic", "abc") }
  end

  def test_repeat_min_atomic_twice
    want = [
      {
        "rule" => "repeat_min_atomic",
        "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_min_atomic", "abcabc").dump)
  end

  def test_repeat_min_atomic_thrice
    want = [
      {
        "rule" => "repeat_min_atomic",
        "span" => { "str" => "abcabcabc", "start" => 0, "end" => 9 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_min_atomic", "abcabcabc").dump)
  end

  def test_repeat_min_atomic_space
    # TODO: => error message
    assert_raises(Pestle::PestParsingError) { PARSER.parse("repeat_min_atomic", "abc abc") }
  end

  def test_repeat_max_once
    want = [
      {
        "rule" => "repeat_max",
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

    assert_equal(want, PARSER.parse("repeat_max", "abc").dump)
  end

  def test_repeat_max_twice
    want = [
      {
        "rule" => "repeat_max",
        "span" => { "str" => "abc abc", "start" => 0, "end" => 7 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 4, "end" => 7 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("repeat_max", "abc abc").dump)
  end

  def test_repeat_max_thrice
    want = [
      {
        "rule" => "repeat_max",
        "span" => { "str" => "abc abc", "start" => 0, "end" => 7 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 4, "end" => 7 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("repeat_max", "abc abc abc").dump)
  end

  def test_repeat_max_atomic_once
    want = [
      {
        "rule" => "repeat_max_atomic",
        "span" => { "str" => "abc", "start" => 0, "end" => 3 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_max_atomic", "abc").dump)
  end

  def test_repeat_max_atomic_once_twice
    want = [
      {
        "rule" => "repeat_max_atomic",
        "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_max_atomic", "abcabc").dump)
  end

  def test_repeat_max_atomic_once_thrice
    want = [
      {
        "rule" => "repeat_max_atomic",
        "span" => { "str" => "abcabc", "start" => 0, "end" => 6 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_max_atomic", "abcabcabc").dump)
  end

  def test_repeat_max_atomic_space
    want = [
      {
        "rule" => "repeat_max_atomic",
        "span" => { "str" => "abc", "start" => 0, "end" => 3 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_max_atomic", "abc abc").dump)
  end

  def test_repeat_comment
    want = [
      {
        "rule" => "repeat_once",
        "span" => { "str" => "abc$$$ $$$abc", "start" => 0, "end" => 13 },
        "inner" => [
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 0, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "string",
            "span" => { "str" => "abc", "start" => 10, "end" => 13 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("repeat_once", "abc$$$ $$$abc").dump)
  end

  def test_soi_at_start
    want = [
      {
        "rule" => "soi_at_start",
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

    assert_equal(want, PARSER.parse("soi_at_start", "abc").dump)
  end

  def test_peek
    want = [
      {
        "rule" => "peek_",
        "span" => { "str" => "0111", "start" => 0, "end" => 4 },
        "inner" => [
          {
            "rule" => "range",
            "span" => { "str" => "0", "start" => 0, "end" => 1 },
            "inner" => []
          },
          {
            "rule" => "range",
            "span" => { "str" => "1", "start" => 1, "end" => 2 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("peek_", "0111").dump)
  end

  def test_peek_all
    want = [
      {
        "rule" => "peek_all",
        "span" => { "str" => "0110", "start" => 0, "end" => 4 },
        "inner" => [
          {
            "rule" => "range",
            "span" => { "str" => "0", "start" => 0, "end" => 1 },
            "inner" => []
          },
          {
            "rule" => "range",
            "span" => { "str" => "1", "start" => 1, "end" => 2 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("peek_all", "0110").dump)
  end

  def test_peek_slice_23
    want = [
      {
        "rule" => "peek_slice_23",
        "span" => { "str" => "0123412", "start" => 0, "end" => 7 },
        "inner" => [
          {
            "rule" => "range",
            "span" => { "str" => "0", "start" => 0, "end" => 1 },
            "inner" => []
          },
          {
            "rule" => "range",
            "span" => { "str" => "1", "start" => 1, "end" => 2 },
            "inner" => []
          },
          {
            "rule" => "range",
            "span" => { "str" => "2", "start" => 2, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "range",
            "span" => { "str" => "3", "start" => 3, "end" => 4 },
            "inner" => []
          },
          {
            "rule" => "range",
            "span" => { "str" => "4", "start" => 4, "end" => 5 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("peek_slice_23", "0123412").dump)
  end

  def test_pop
    want = [
      {
        "rule" => "pop_",
        "span" => { "str" => "0110", "start" => 0, "end" => 4 },
        "inner" => [
          {
            "rule" => "range",
            "span" => { "str" => "0", "start" => 0, "end" => 1 },
            "inner" => []
          },
          {
            "rule" => "range",
            "span" => { "str" => "1", "start" => 1, "end" => 2 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("pop_", "0110").dump)
  end

  def test_pop_all
    want = [
      {
        "rule" => "pop_all",
        "span" => { "str" => "0110", "start" => 0, "end" => 4 },
        "inner" => [
          {
            "rule" => "range",
            "span" => { "str" => "0", "start" => 0, "end" => 1 },
            "inner" => []
          },
          {
            "rule" => "range",
            "span" => { "str" => "1", "start" => 1, "end" => 2 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("pop_all", "0110").dump)
  end

  def test_pop_fail
    want = [
      {
        "rule" => "pop_fail",
        "span" => { "str" => "010", "start" => 0, "end" => 3 },
        "inner" => [
          {
            "rule" => "range",
            "span" => { "str" => "0", "start" => 0, "end" => 1 },
            "inner" => []
          },
          {
            "rule" => "range",
            "span" => { "str" => "1", "start" => 1, "end" => 2 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("pop_fail", "010").dump)
  end

  def test_repeat_mutate_stack
    want = [
      {
        "rule" => "repeat_mutate_stack",
        "span" => { "str" => "a,b,c,cba", "start" => 0, "end" => 9 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("repeat_mutate_stack", "a,b,c,cba").dump)
  end
end
