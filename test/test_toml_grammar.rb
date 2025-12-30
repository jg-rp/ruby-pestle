# frozen_string_literal: true

# These tests are translated from Rust pest's `toml.rs`.
#
# https://github.com/pest-parser/pest/blob/master/grammars/tests/toml.rs
#
# See LICENSE_PEST.txt

require "pathname"
require "test_helper"

class TestTOMLGrammar < Minitest::Test
  make_my_diffs_pretty!

  GRAMMAR = Pathname.new("test/grammars/toml.pest")
  PARSER = Pestle::Parser.from_grammar(GRAMMAR.read)

  def test_boolean_rule
    want = [
      { "rule" => "boolean", "span" => { "str" => "true", "start" => 0, "end" => 4 },
        "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("boolean", "true").dump)
  end

  def test_integer_rule
    want = [
      {
        "rule" => "integer",
        "span" => { "str" => "+1_000_0", "start" => 0, "end" => 8 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("integer", "+1_000_0").dump)
  end

  def test_float_rule
    want = [
      {
        "rule" => "float",
        "span" => { "str" => "+1_0.0_1e+100", "start" => 0, "end" => 13 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("float", "+1_0.0_1e+100").dump)
  end

  def test_partial_time_rule
    want = [
      {
        "rule" => "partial_time",
        "span" => { "str" => "12:34:56.000", "start" => 0, "end" => 12 },
        "inner" => [
          {
            "rule" => "time_hour",
            "span" => { "str" => "12", "start" => 0, "end" => 2 },
            "inner" => []
          },
          {
            "rule" => "time_minute",
            "span" => { "str" => "34", "start" => 3, "end" => 5 },
            "inner" => []
          },
          {
            "rule" => "time_second",
            "span" => { "str" => "56", "start" => 6, "end" => 8 },
            "inner" => []
          },
          {
            "rule" => "time_secfrac",
            "span" => { "str" => ".000", "start" => 8, "end" => 12 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("partial_time", "12:34:56.000").dump)
  end

  def test_full_date_rule
    want = [
      {
        "rule" => "full_date",
        "span" => { "str" => "2001-12-13", "start" => 0, "end" => 10 },
        "inner" => [
          {
            "rule" => "date_fullyear",
            "span" => { "str" => "2001", "start" => 0, "end" => 4 },
            "inner" => []
          },
          {
            "rule" => "date_month",
            "span" => { "str" => "12", "start" => 5, "end" => 7 },
            "inner" => []
          },
          {
            "rule" => "date_mday",
            "span" => { "str" => "13", "start" => 8, "end" => 10 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("full_date", "2001-12-13").dump)
  end

  def test_local_date_time_rule
    want = [
      {
        "rule" => "local_date_time",
        "span" => { "str" => "2001-12-13T12:34:56.000", "start" => 0, "end" => 23 },
        "inner" => [
          {
            "rule" => "full_date",
            "span" => { "str" => "2001-12-13", "start" => 0, "end" => 10 },
            "inner" => [
              {
                "rule" => "date_fullyear",
                "span" => { "str" => "2001", "start" => 0, "end" => 4 },
                "inner" => []
              },
              {
                "rule" => "date_month",
                "span" => { "str" => "12", "start" => 5, "end" => 7 },
                "inner" => []
              },
              {
                "rule" => "date_mday",
                "span" => { "str" => "13", "start" => 8, "end" => 10 },
                "inner" => []
              }
            ]
          },
          {
            "rule" => "partial_time",
            "span" => { "str" => "12:34:56.000", "start" => 11, "end" => 23 },
            "inner" => [
              {
                "rule" => "time_hour",
                "span" => { "str" => "12", "start" => 11, "end" => 13 },
                "inner" => []
              },
              {
                "rule" => "time_minute",
                "span" => { "str" => "34", "start" => 14, "end" => 16 },
                "inner" => []
              },
              {
                "rule" => "time_second",
                "span" => { "str" => "56", "start" => 17, "end" => 19 },
                "inner" => []
              },
              {
                "rule" => "time_secfrac",
                "span" => { "str" => ".000", "start" => 19, "end" => 23 },
                "inner" => []
              }
            ]
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("local_date_time", "2001-12-13T12:34:56.000").dump)
  end

  def test_date_time_rule
    want = [
      {
        "rule" => "date_time",
        "span" => { "str" => "2001-12-13T12:34:56.000Z", "start" => 0, "end" => 24 },
        "inner" => [
          {
            "rule" => "full_date",
            "span" => { "str" => "2001-12-13", "start" => 0, "end" => 10 },
            "inner" => [
              {
                "rule" => "date_fullyear",
                "span" => { "str" => "2001", "start" => 0, "end" => 4 },
                "inner" => []
              },
              {
                "rule" => "date_month",
                "span" => { "str" => "12", "start" => 5, "end" => 7 },
                "inner" => []
              },
              {
                "rule" => "date_mday",
                "span" => { "str" => "13", "start" => 8, "end" => 10 },
                "inner" => []
              }
            ]
          },
          {
            "rule" => "full_time",
            "span" => { "str" => "12:34:56.000Z", "start" => 11, "end" => 24 },
            "inner" => [
              {
                "rule" => "partial_time",
                "span" => { "str" => "12:34:56.000", "start" => 11, "end" => 23 },
                "inner" => [
                  {
                    "rule" => "time_hour",
                    "span" => { "str" => "12", "start" => 11, "end" => 13 },
                    "inner" => []
                  },
                  {
                    "rule" => "time_minute",
                    "span" => { "str" => "34", "start" => 14, "end" => 16 },
                    "inner" => []
                  },
                  {
                    "rule" => "time_second",
                    "span" => { "str" => "56", "start" => 17, "end" => 19 },
                    "inner" => []
                  },
                  {
                    "rule" => "time_secfrac",
                    "span" => { "str" => ".000", "start" => 19, "end" => 23 },
                    "inner" => []
                  }
                ]
              },
              {
                "rule" => "time_offset",
                "span" => { "str" => "Z", "start" => 23, "end" => 24 },
                "inner" => []
              }
            ]
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("date_time", "2001-12-13T12:34:56.000Z").dump)
  end

  def test_literal_rule
    want = [
      { "rule" => "literal", "span" => { "str" => "'\"'", "start" => 0, "end" => 3 },
        "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("literal", "'\"'").dump)
  end

  def test_multi_line_literal_rule
    want = [
      {
        "rule" => "multi_line_literal",
        "span" => { "str" => "'''\"'''", "start" => 0, "end" => 7 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("multi_line_literal", "'''\"'''").dump)
  end

  def test_string_rule
    want = [
      { "rule" => "string", "span" => { "str" => "\"\\n\"", "start" => 0, "end" => 4 },
        "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("string", "\"\\n\"").dump)
  end

  def test_multi_line_string_rule
    want = [
      {
        "rule" => "multi_line_string",
        "span" => { "str" => "\"\"\" \\n \"\"\"", "start" => 0, "end" => 10 },
        "inner" => []
      }
    ]

    assert_equal(want, PARSER.parse("multi_line_string", "\"\"\" \\n \"\"\"").dump)
  end

  def test_empty_array
    want = [
      { "rule" => "array", "span" => { "str" => "[ ]", "start" => 0, "end" => 3 }, "inner" => [] }
    ]

    assert_equal(want, PARSER.parse("array", "[ ]").dump)
  end

  def test_array_rule
    want = [
      {
        "rule" => "array",
        "span" => { "str" => "['', 2017-08-09, 20.0]", "start" => 0, "end" => 22 },
        "inner" => [
          {
            "rule" => "literal",
            "span" => { "str" => "''", "start" => 1, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "full_date",
            "span" => { "str" => "2017-08-09", "start" => 5, "end" => 15 },
            "inner" => [
              {
                "rule" => "date_fullyear",
                "span" => { "str" => "2017", "start" => 5, "end" => 9 },
                "inner" => []
              },
              {
                "rule" => "date_month",
                "span" => { "str" => "08", "start" => 10, "end" => 12 },
                "inner" => []
              },
              {
                "rule" => "date_mday",
                "span" => { "str" => "09", "start" => 13, "end" => 15 },
                "inner" => []
              }
            ]
          },
          {
            "rule" => "float",
            "span" => { "str" => "20.0", "start" => 17, "end" => 21 },
            "inner" => []
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("array", "['', 2017-08-09, 20.0]").dump)
  end

  def test_inline_table_rule
    want = [
      {
        "rule" => "inline_table",
        "span" => { "str" => "{ a = 'b' }", "start" => 0, "end" => 11 },
        "inner" => [
          {
            "rule" => "pair",
            "span" => { "str" => "a = 'b'", "start" => 2, "end" => 9 },
            "inner" => [
              {
                "rule" => "key",
                "span" => { "str" => "a", "start" => 2, "end" => 3 },
                "inner" => []
              },
              {
                "rule" => "literal",
                "span" => { "str" => "'b'", "start" => 6, "end" => 9 },
                "inner" => []
              }
            ]
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("inline_table", "{ a = 'b' }").dump)
  end

  def test_table_rule
    want = [
      {
        "rule" => "table",
        "span" => { "str" => "[a.b]\nc = 'd'", "start" => 0, "end" => 13 },
        "inner" => [
          {
            "rule" => "key",
            "span" => { "str" => "a", "start" => 1, "end" => 2 },
            "inner" => []
          },
          {
            "rule" => "key",
            "span" => { "str" => "b", "start" => 3, "end" => 4 },
            "inner" => []
          },
          {
            "rule" => "pair",
            "span" => { "str" => "c = 'd'", "start" => 6, "end" => 13 },
            "inner" => [
              {
                "rule" => "key",
                "span" => { "str" => "c", "start" => 6, "end" => 7 },
                "inner" => []
              },
              {
                "rule" => "literal",
                "span" => { "str" => "'d'", "start" => 10, "end" => 13 },
                "inner" => []
              }
            ]
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("table", "[a.b]\nc = 'd'").dump)
  end

  def test_array_table_rule
    want = [
      {
        "rule" => "array_table",
        "span" => { "str" => "[[a.b]]\nc = 'd'", "start" => 0, "end" => 15 },
        "inner" => [
          {
            "rule" => "key",
            "span" => { "str" => "a", "start" => 2, "end" => 3 },
            "inner" => []
          },
          {
            "rule" => "key",
            "span" => { "str" => "b", "start" => 4, "end" => 5 },
            "inner" => []
          },
          {
            "rule" => "pair",
            "span" => { "str" => "c = 'd'", "start" => 8, "end" => 15 },
            "inner" => [
              {
                "rule" => "key",
                "span" => { "str" => "c", "start" => 8, "end" => 9 },
                "inner" => []
              },
              {
                "rule" => "literal",
                "span" => { "str" => "'d'", "start" => 12, "end" => 15 },
                "inner" => []
              }
            ]
          }
        ]
      }
    ]

    assert_equal(want, PARSER.parse("array_table", "[[a.b]]\nc = 'd'").dump)
  end

  def test_example
    example = Pathname.new("test/examples/example.toml").read
    PARSER.parse("toml", example)
  end
end
