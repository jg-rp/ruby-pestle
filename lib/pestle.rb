# frozen_string_literal: true

require_relative "pestle/version"
require_relative "pestle/grammar/lexer"
require_relative "pestle/grammar/parser"
require_relative "pestle/pair"
require_relative "pestle/parser"

module Pestle
  def self.parse_grammar(grammar)
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)
    parser = Pestle::Grammar::Parser.new(grammar, tokens)
    parser.parse
  end
end
