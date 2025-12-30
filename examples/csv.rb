# frozen_string_literal: true

# A translation of the CSV example found in the pest book.
# https://pest.rs/book/examples/csv.html

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

# NOTE: This simple example grammar requires input CSV to include a trailing
# `\r\n` or `\n`. Without it you will get a `PestParsingError`.

GRAMMAR = <<~'GRAMMAR'
  field = { (ASCII_DIGIT | "." | "-")+ }
  record = { field ~ ("," ~ field)* }
  file = { SOI ~ (record ~ ("\r\n" | "\n"))* ~ EOI }
GRAMMAR

EXAMPLE_DATA = <<~CSV
  65279,1179403647,1463895090
  3.1415927,2.7182817,1.618034
  -40,-273.15
  13,42
  65537
CSV

# The name of the rule to start parsing from. Can be a string or a symbol.
START_RULE = :file

parser = Pestle::Parser.from_grammar(GRAMMAR)
token_pairs = parser.parse(START_RULE, EXAMPLE_DATA).first

field_sum = 0.0
record_count = 0

token_pairs.each do |pair|
  case pair
  in :record, fields
    record_count += 1
    fields.each { |field| field_sum += field.text.to_f }
  in :EOI, _
    break
  else
    raise "unexpected rule #{pair.name}"
  end
end

puts "Sum of fields: #{field_sum}"
puts "Number of records: #{record_count}"
