# frozen_string_literal: true

require "pathname"
require_relative "../../../lib/pestle"
require_relative "ast"

module JSONPathPest
  GRAMMAR = Pathname.new("examples/jsonpath/jsonpath.pest")

  PEST_PARSER = Pestle::Parser.from_grammar(GRAMMAR.read)

  START_RULE = :jsonpath

  FUNCTION_EXTENSIONS = {
    "length" => Length.new,
    "count" => Count.new,
    "value" => Value.new,
    "match" => Match.new,
    "search" => Search.new
  }.freeze

  MAX_INT_INDEX = (2**53) - 1
  MIN_INT_INDEX = -(2**53) + 1

  def parse(query)
    segments = self::PEST_PARSER.parse(self::START_RULE, query)
    raise "expected end of input" unless segments.pop&.rule == :EOI

    Query.new(segments.map { |pair| parse_segment(pair) })
  end

  def parse_segment(pair)
    case pair
    in :child_segment, [inner]
      ChildSegment.new(pair, parse_segment_inner(inner))
    in :descendant_segment, [inner]
      DescendantSegment.new(pair, parse_segment_inner(inner))
    in :name_segment | :index_segment, [inner]
      ChildSegment.new(pair, [parse_selector(inner)])
    else
      raise "expected a segment"
    end
  end

  def parse_segment_inner(pair)
    case pair
    in :bracketed_selection, selectors
      selectors.map { |selector| parse_selector(selector) }
    in :wildcard_selector, _
      [WildcardSelector.new(pair)]
    in :member_name_shorthand, _
      [NameSelector.new(pair, pair.text)]
    else
      raise "expected a shorthand selector or bracketed selection"
    end
  end
end
