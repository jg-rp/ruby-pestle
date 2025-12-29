# frozen_string_literal: true

# These tests are translated from Rust pest's `lists.rs`.
#
# https://github.com/pest-parser/pest/blob/master/derive/tests/lists.rs
#
# See LICENSE_PEST.txt

require "pathname"
require "test_helper"

class TestListsGrammar < Minitest::Test
  make_my_diffs_pretty!

  GRAMMAR = Pathname.new("test/grammars/lists.pest")
  PARSER = Pestle::Parser.from_grammar(GRAMMAR.read)

  def test_item
    want = [
      { "rule" => "item", "span" => { "str" => "a", "start" => 2, "end" => 3 }, "inner" => [] },
      { "rule" => "EOI", "span" => { "str" => "", "start" => 3, "end" => 3 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("lists", "- a").dump)
  end

  def test_items
    want = [
      { "rule" => "item", "span" => { "str" => "a", "start" => 2, "end" => 3 }, "inner" => [] },
      { "rule" => "item", "span" => { "str" => "b", "start" => 6, "end" => 7 }, "inner" => [] },
      { "rule" => "EOI", "span" => { "str" => "", "start" => 7, "end" => 7 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("lists", "- a\n- b").dump)
  end

  def test_children
    want = [
      {
        "rule" => "children",
        "span" => { "str" => "  - b", "start" => 0, "end" => 5 },
        "inner" => [
          {
            "rule" => "item",
            "span" => { "str" => "b", "start" => 4, "end" => 5 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("children", "  - b").dump)
  end

  def test_nested_item
    want = [
      { "rule" => "item", "span" => { "str" => "a", "start" => 2, "end" => 3 }, "inner" => [] },
      {
        "rule" => "children",
        "span" => { "str" => "  - b", "start" => 4, "end" => 9 },
        "inner" => [
          {
            "rule" => "item",
            "span" => { "str" => "b", "start" => 8, "end" => 9 },
            "inner" => []
          }
        ]
      },
      { "rule" => "EOI", "span" => { "str" => "", "start" => 9, "end" => 9 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("lists", "- a\n  - b").dump)
  end

  def test_nested_items
    want = [
      { "rule" => "item", "span" => { "str" => "a", "start" => 2, "end" => 3 }, "inner" => [] },
      {
        "rule" => "children",
        "span" => { "str" => "  - b\n  - c", "start" => 4, "end" => 15 },
        "inner" => [
          {
            "rule" => "item",
            "span" => { "str" => "b", "start" => 8, "end" => 9 },
            "inner" => []
          },
          {
            "rule" => "item",
            "span" => { "str" => "c", "start" => 14, "end" => 15 },
            "inner" => []
          }
        ]
      },
      { "rule" => "EOI", "span" => { "str" => "", "start" => 15, "end" => 15 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("lists", "- a\n  - b\n  - c").dump)
  end

  def test_nested_two_levels
    want = [
      { "rule" => "item", "span" => { "str" => "a", "start" => 2, "end" => 3 }, "inner" => [] },
      {
        "rule" => "children",
        "span" => { "str" => "  - b\n    - c", "start" => 4, "end" => 17 },
        "inner" => [
          {
            "rule" => "item",
            "span" => { "str" => "b", "start" => 8, "end" => 9 },
            "inner" => []
          },
          {
            "rule" => "children",
            "span" => { "str" => "    - c", "start" => 10, "end" => 17 },
            "inner" => [
              {
                "rule" => "item",
                "span" => { "str" => "c", "start" => 16, "end" => 17 },
                "inner" => []
              }
            ]
          }
        ]
      },
      { "rule" => "EOI", "span" => { "str" => "", "start" => 17, "end" => 17 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("lists", "- a\n  - b\n    - c").dump)
  end

  def test_nested_then_not
    want = [
      { "rule" => "item", "span" => { "str" => "a", "start" => 2, "end" => 3 }, "inner" => [] },
      {
        "rule" => "children",
        "span" => { "str" => "  - b", "start" => 4, "end" => 9 },
        "inner" => [
          {
            "rule" => "item",
            "span" => { "str" => "b", "start" => 8, "end" => 9 },
            "inner" => []
          }
        ]
      },
      { "rule" => "item", "span" => { "str" => "c", "start" => 12, "end" => 13 }, "inner" => [] },
      { "rule" => "EOI", "span" => { "str" => "", "start" => 13, "end" => 13 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("lists", "- a\n  - b\n- c").dump)
  end
end
