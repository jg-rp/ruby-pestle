# frozen_string_literal: true

# These tests are translated from Rust pest's `http.rs`.
#
# https://github.com/pest-parser/pest/blob/master/grammars/tests/http.rs
#
# See LICENSE_PEST.txt

require "pathname"
require "test_helper"

class TestHTTPGrammar < Minitest::Test
  make_my_diffs_pretty!

  GRAMMAR = Pathname.new("test/grammars/http.pest")
  PARSER = Pestle::Parser.from_grammar(GRAMMAR.read)

  def test_method_rule
    want = [
      { "rule" => "method", "span" => { "str" => "GET", "start" => 0, "end" => 3 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("method", "GET").dump)
  end

  def test_uri_rule
    want = [
      { "rule" => "uri", "span" => { "str" => "/", "start" => 0, "end" => 1 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("uri", "/").dump)
  end

  def test_version_rule
    want = [
      { "rule" => "version", "span" => { "str" => "1.1", "start" => 0, "end" => 3 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("version", "1.1").dump)
  end

  def test_header
    want = [
      {
        "rule" => "header",
        "span" => { "str" => "Connection: keep-alive\n", "start" => 0, "end" => 23 },
        "inner" => [
          {
            "rule" => "header_name",
            "span" => { "str" => "Connection", "start" => 0, "end" => 10 },
            "inner" => []
          },
          {
            "rule" => "header_value",
            "span" => { "str" => "keep-alive", "start" => 12, "end" => 22 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("header", "Connection: keep-alive\n").dump)
  end

  def test_example
    example = Pathname.new("test/examples/example.http").read
    PARSER.parse("http", example)
  end
end
