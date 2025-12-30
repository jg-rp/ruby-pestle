# frozen_string_literal: true

# A translation of the json example found in the pest book.
# https://pest.rs/book/examples/json.html

# https://github.com/pest-parser/book/blob/master/LICENSE-MIT
#
# Permission is hereby granted, free of charge, to any
# person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the
# Software without restriction, including without
# limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF
# ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
# SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

require_relative "../lib/pestle"

GRAMMAR = <<~'GRAMMAR'
  WHITESPACE = _{ " " | "\t" | "\r" | "\n" }

  object = {
      "{" ~ "}" |
      "{" ~ pair ~ ("," ~ pair)* ~ "}"
  }
  pair = { string ~ ":" ~ value }

  array = {
      "[" ~ "]" |
      "[" ~ value ~ ("," ~ value)* ~ "]"
  }

  value = _{ object | array | string | number | boolean | null }

  boolean = { "true" | "false" }

  null = { "null" }

  string = ${ "\"" ~ inner ~ "\"" }
  inner = @{ char* }
  char = {
      !("\"" | "\\") ~ ANY
      | "\\" ~ ("\"" | "\\" | "/" | "b" | "f" | "n" | "r" | "t")
      | "\\" ~ ("u" ~ ASCII_HEX_DIGIT{4})
  }

  number = @{
      "-"?
      ~ ("0" | ASCII_NONZERO_DIGIT ~ ASCII_DIGIT*)
      ~ ("." ~ ASCII_DIGIT*)?
      ~ (^"e" ~ ("+" | "-")? ~ ASCII_DIGIT+)?
  }

  json = _{ SOI ~ (object | array) ~ EOI }
GRAMMAR

EXAMPLE_JSON = <<~'DATA'
  {
    "nesting": { "inner object": {} },
    "an array": [1.5, true, null, 1e-6],
    "string with escaped double quotes": "\"quick brown foxes\""
  }
DATA

PARSER = Pestle::Parser.from_grammar(GRAMMAR)

START_RULE = :json

# Very basic abstract syntax tree (AST) nodes.

JSONObject = Struct.new("JSONObject", :items) do
  def dumps = "{#{items.each.map { |k, v| "\"#{k}\": #{v.dumps}" }.join(",")}}"
end

JSONArray = Struct.new("JSONArray", :items) do
  def dumps = "[#{items.map(&:dumps).join(",")}]"
end

JSONString = Struct.new("JSONString", :value) do
  def dumps = "\"#{value}\""
end

JSONNumber = Struct.new("JSONNumber", :value) do
  def dumps = value.to_s
end

JSONBool = Struct.new("JSONBool", :value) do
  def dumps = value.to_s
end

JSONNull = Struct.new("JSONNull") do
  def dumps = "null"
end

# JSON parser entry point.
# @param data [String]
# @return [JSONValue] One of the JSON nodes defined above.
def parse_json(data)
  pair = PARSER.parse(START_RULE, data).first
  parse_json_value(pair)
end

# Recursively parse a JSON value from a token pair.
def parse_json_value(pair)
  case pair
  in :object, inner
    JSONObject.new(inner.map { |k, v| [k.inner.first.text, parse_json_value(v)] })
  in :array, inner
    JSONArray.new(inner.map { |v| parse_json_value(v) })
  in :string, [inner]
    JSONString.new(inner.text)
  in :number, _
    JSONNumber.new(pair.text.to_f)
  in :boolean, _
    JSONBool.new(pair.text == "true")
  in :null, _
    JSONNull.new
  else
    raise "unexpected rule #{pair.name.inspect}"
  end
end

json = parse_json(EXAMPLE_JSON)
puts json.dumps
