# frozen_string_literal: true

# A translation of the ini example found in the pest book.
# https://pest.rs/book/examples/ini.html

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

require "json"
require_relative "../lib/pestle"

GRAMMAR = <<~GRAMMAR
  file = {
      SOI ~
      ((section | property)? ~ NEWLINE)* ~
      EOI
  }

  char = { ASCII_ALPHANUMERIC | "." | "_" | "/" }
  name = @{ char+ }
  value = @{ char* }
  section = { "[" ~ name ~ "]" }
  property = { name ~ "=" ~ value }

  WHITESPACE = _{ " " }
GRAMMAR

EXAMPLE_INI = <<~INI
  username = noha
  password = plain_text
  salt = NaCl

  [server_1]
  interface=eth0
  ip=127.0.0.1
  document_root=/var/www/example.org

  [empty_section]

  [second_server]
  document_root=/var/www/example.com
  ip=
  interface=eth1
INI

START_RULE = :file

parser = Pestle::Parser.from_grammar(GRAMMAR)
pairs = parser.parse(START_RULE, EXAMPLE_INI).first

current_section_name = ""
properties = Hash.new { |hash, key| hash[key] = {} }

pairs.each do |pair|
  case pair
  in :section, [name]
    current_section_name = name.text
  in :property, [name, value]
    properties[current_section_name][name.text] = value.text
  in :EOI, _
    break
  else
    raise "unexpected rule #{pair.name.inspect}"
  end
end

puts JSON.pretty_generate(properties)
