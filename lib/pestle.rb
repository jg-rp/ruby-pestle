# frozen_string_literal: true

require_relative "pestle/version"
require_relative "pestle/grammar/lexer"
require_relative "pestle/grammar/parser"
require_relative "pestle/pair"
require_relative "pestle/parser"
require_relative "pestle/pratt"

# A Pest-like parser interpreter.
module Pestle
  # Parse a Pest grammar into a hash of grammar rules.
  #
  # Usually you'll want `Pestle::Parser.from_grammar(grammar)` instead.
  #
  # @param grammar [String]
  # @return [[Hash[String, Pestle::Grammar::Rule], String?]] A mapping of rule
  #   name to Rule instance and any associated grammar doc.
  def self.parse_grammar(grammar)
    tokens = Pestle::Grammar::Lexer.tokenize(grammar)
    parser = Pestle::Grammar::Parser.new(grammar, tokens)
    parser.parse
  end
end
