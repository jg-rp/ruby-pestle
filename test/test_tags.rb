# frozen_string_literal: true

require "test_helper"

class TestTags < Minitest::Test
  make_my_diffs_pretty!

  GRAMMAR = <<~GRAMMAR
    expr = {
        SOI ~
        #prefix=(STAR)? ~ #suffix=DOT?
        ~ EOI
    }

    STAR={"*"}
    DOT={"."}
  GRAMMAR

  PARSER = Pestle::Parser.from_grammar(GRAMMAR)

  def test_opt_tag_star
    pairs = PARSER.parse("expr", "*")
    pair = pairs.find_first_tagged("prefix")

    assert_equal("STAR", pair.name)
    assert_equal("*", pair.to_s)
    assert_nil(pairs.find_first_tagged("suffix"))
  end

  def test_opt_tag_dot
    pairs = PARSER.parse("expr", ".")
    pair = pairs.find_first_tagged("suffix")

    assert_equal("DOT", pair.name)
    assert_equal(".", pair.to_s)
    assert_nil(pairs.find_first_tagged("prefix"))
  end

  def test_opt_tag_empty
    pairs = PARSER.parse("expr", "")

    assert_nil(pairs.find_first_tagged("prefix"))
    assert_nil(pairs.find_first_tagged("suffix"))
  end
end
