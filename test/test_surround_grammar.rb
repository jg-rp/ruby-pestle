# frozen_string_literal: true

# These tests are translated from Rust pest's `surround.rs`.
#
# https://github.com/pest-parser/pest/blob/master/derive/tests/surround.rs
#
# See LICENSE_PEST.txt

require "pathname"
require "test_helper"

class TestSurroundGrammar < Minitest::Test
  make_my_diffs_pretty!

  GRAMMAR = Pathname.new("test/grammars/surround.pest")
  PARSER = Pestle::Parser.from_grammar(GRAMMAR.read)

  def test_item
    want = [
      {
        "rule" => "QuoteChars",
        "span" => { "str" => "abc", "start" => 1, "end" => 4 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("Quote", "(abc)").dump)
  end
end
