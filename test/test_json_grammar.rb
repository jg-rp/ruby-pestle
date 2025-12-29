# frozen_string_literal: true

# These tests are translated from Rust pest's `json.rs`.
#
# https://github.com/pest-parser/pest/blob/master/grammars/tests/json.rs
#
# See LICENSE_PEST.txt

require "pathname"
require "test_helper"

class TestJSONGrammar < Minitest::Test
  make_my_diffs_pretty!

  GRAMMAR = Pathname.new("test/grammars/json.pest")
  PARSER = Pestle::Parser.from_grammar(GRAMMAR.read)

  def test_null_rule
    want = [
      { "rule" => "null", "span" => { "str" => "null", "start" => 0, "end" => 4 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("null", "null").dump)
  end

  def test_bool_rule
    want = [
      { "rule" => "bool", "span" => { "str" => "false", "start" => 0, "end" => 5 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("bool", "false").dump)
  end

  def test_number_rule_zero
    want = [
      { "rule" => "number", "span" => { "str" => "0", "start" => 0, "end" => 1 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("number", "0").dump)
  end

  def test_number_rule_float
    want = [
      {
        "rule" => "number",
        "span" => { "str" => "100.001", "start" => 0, "end" => 7 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("number", "100.001").dump)
  end

  def test_number_rule_float_exp
    want = [
      {
        "rule" => "number",
        "span" => { "str" => "100.001E+100", "start" => 0, "end" => 12 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("number", "100.001E+100").dump)
  end

  def test_number_rule_minus_zero
    want = [
      {
        "rule" => "number",
        "span" => { "str" => "-0", "start" => 0, "end" => 2 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("number", "-0").dump)
  end

  def test_string_rule_with_escape
    want = [
      {
        "rule" => "string",
        "span" => { "str" => '"asd\\u0000\\""', "start" => 0, "end" => 13 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("string", '"asd\\u0000\\""').dump)
  end

  def test_array_rule_empty
    want = [
      {
        "rule" => "array",
        "span" => { "str" => "[ ]", "start" => 0, "end" => 3 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("array", "[ ]").dump)
  end

  def test_array_rule
    want = [
      {
        "rule" => "array",
        "span" => { "str" => '[0.0e1, false, null, "a", [0]]', "start" => 0, "end" => 30 },
        "inner" => [
          {
            "rule" => "value",
            "span" => { "str" => "0.0e1", "start" => 1, "end" => 6 },
            "inner" => [
              {
                "rule" => "number",
                "span" => { "str" => "0.0e1", "start" => 1, "end" => 6 },
                "inner" => []
              }
            ]
          },
          {
            "rule" => "value",
            "span" => { "str" => "false", "start" => 8, "end" => 13 },
            "inner" => [
              {
                "rule" => "bool",
                "span" => { "str" => "false", "start" => 8, "end" => 13 },
                "inner" => []
              }
            ]
          },
          {
            "rule" => "value",
            "span" => { "str" => "null", "start" => 15, "end" => 19 },
            "inner" => [
              {
                "rule" => "null",
                "span" => { "str" => "null", "start" => 15, "end" => 19 },
                "inner" => []
              }
            ]
          },
          {
            "rule" => "value",
            "span" => { "str" => '"a"', "start" => 21, "end" => 24 },
            "inner" => [
              {
                "rule" => "string",
                "span" => { "str" => '"a"', "start" => 21, "end" => 24 },
                "inner" => []
              }
            ]
          },
          {
            "rule" => "value",
            "span" => { "str" => "[0]", "start" => 26, "end" => 29 },
            "inner" => [
              {
                "rule" => "array",
                "span" => { "str" => "[0]", "start" => 26, "end" => 29 },
                "inner" => [
                  {
                    "rule" => "value",
                    "span" => { "str" => "0", "start" => 27, "end" => 28 },
                    "inner" => [
                      {
                        "rule" => "number",
                        "span" => {
                          "str" => "0",
                          "start" => 27,
                          "end" => 28
                        },
                        "inner" => []
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("array", '[0.0e1, false, null, "a", [0]]').dump)
  end

  def test_object_rule
    want = [
      {
        "rule" => "object",
        "span" => { "str" => '{"a" : 3, "b" : [{}, 3]}', "start" => 0, "end" => 24 },
        "inner" => [
          {
            "rule" => "pair",
            "span" => { "str" => '"a" : 3', "start" => 1, "end" => 8 },
            "inner" => [
              {
                "rule" => "string",
                "span" => { "str" => '"a"', "start" => 1, "end" => 4 },
                "inner" => []
              },
              {
                "rule" => "value",
                "span" => { "str" => "3", "start" => 7, "end" => 8 },
                "inner" => [
                  {
                    "rule" => "number",
                    "span" => { "str" => "3", "start" => 7, "end" => 8 },
                    "inner" => []
                  }
                ]
              }
            ]
          },
          {
            "rule" => "pair",
            "span" => { "str" => '"b" : [{}, 3]', "start" => 10, "end" => 23 },
            "inner" => [
              {
                "rule" => "string",
                "span" => { "str" => '"b"', "start" => 10, "end" => 13 },
                "inner" => []
              },
              {
                "rule" => "value",
                "span" => { "str" => "[{}, 3]", "start" => 16, "end" => 23 },
                "inner" => [
                  {
                    "rule" => "array",
                    "span" => { "str" => "[{}, 3]", "start" => 16, "end" => 23 },
                    "inner" => [
                      {
                        "rule" => "value",
                        "span" => {
                          "str" => "{}",
                          "start" => 17,
                          "end" => 19
                        },
                        "inner" => [
                          {
                            "rule" => "object",
                            "span" => {
                              "str" => "{}",
                              "start" => 17,
                              "end" => 19
                            },
                            "inner" => []
                          }
                        ]
                      },
                      {
                        "rule" => "value",
                        "span" => {
                          "str" => "3",
                          "start" => 21,
                          "end" => 22
                        },
                        "inner" => [
                          {
                            "rule" => "number",
                            "span" => {
                              "str" => "3",
                              "start" => 21,
                              "end" => 22
                            },
                            "inner" => []
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("object", '{"a" : 3, "b" : [{}, 3]}').dump)
  end

  def test_example
    example = Pathname.new("test/examples/example.json").read
    PARSER.parse("json", example)
  end

  def test_line_col_span
    example = Pathname.new("test/examples/example.json").read
    expected = Pathname.new("test/examples/example.line-col.txt").read

    pairs = PARSER.parse("json", example)
    out = [] # : Array[String]

    pairs.flatten.each do |pair|
      next unless pair.children.empty?

      span = pair.span
      line, col = span.start_pos.line_col
      span_s = span.to_s.sub("\n", "\\n")
      out << "(#{line}:#{col}) #{span_s}\n"
    end

    assert_equal(out.join.strip, expected.strip)
  end
end
