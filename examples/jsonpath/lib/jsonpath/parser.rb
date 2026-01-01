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
    pairs = self::PEST_PARSER.parse(self::START_RULE, query)
    segments = []

    pairs.each do |pair|
      case pair
      in :child_segment, [inner]
        segments << ChildSegment.new(pair, parse_segment_inner(inner))
      in :descendant_segment, [inner]
        segments << DescendantSegment.new(pair, parse_segment_inner(inner))
      in :name_segment | :index_segment, [inner]
        segments << ChildSegment.new(pair, [parse_selector(inner)])
      in :EOI
        break
      else
        raise "expected a segment"
      end
    end

    Query.new(segments)
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

  def parse_selector(pair)
    case pair
    in :double_quoted, _
      NameSelector.new(pair, unescape(pair.text, '"'))
    in :single_quoted, _
      NameSelector.new(pair, unescape(pair.text, "'"))
    in :wildcard_selector, _
      WildcardSelector.new(pair)
    in :slice_selector, _
      parse_slice_selector(pair)
    in :index_selector, _
      IndexSelector.new(pair, i_json_int(pair.text))
    in :filter_selector, [expression]
      FilterSelector.new(pair, parse_logical_or_expression(expression))
    in :member_name_shorthand, _
      NameSelector.new(pair, pair.text)
    else
      raise "expected a selector"
    end
  end

  def parse_slice_selector(pair)
    start = nil
    stop = nil
    step = nil

    pair.each do |child|
      case child.rule
      when :start
        start = i_json_int(child.text)
      when :stop
        stop = i_json_int(child.text)
      when :step
        step = i_json_int(child.text)
      else
        raise "expected a slice index"
      end
    end

    SliceSelector.new(pair, start, stop, step)
  end

  def parse_logical_or_expression(pair, func_expr: false)
    first, *rest = pair.children
    init = parse_logical_and_expression(first, func_expr: func_expr)
    return init if rest.empty?

    rest.reduce(init) do |acc, pair|
      right = parse_logical_and_expression(pair, func_expr: func_expr)
      LogicalOrExpression.new(pair, acc, right)
    end
  end

  def parse_logical_and_expression(pair, func_expr: false)
    first, *rest = pair.children
    init = parse_basic_expression(first)
    assert_compared(init) unless func_expr
    return init if rest.empty?

    rest.reduce(init) do |acc, pair|
      right = parse_basic_expression(pair)
      assert_compared(right) unless func_expr
      LogicalAndExpression.new(pair, acc, right)
    end
  end

  def parse_basic_expression(pair)
    case pair
    in :paren_expr, [not_expr, or_expr]
      LogicalNotExpression.new(not_expr, parse_logical_or_expression(or_expr))
    in :paren_expr, [or_expr]
      parse_logical_or_expression(or_expr)
    in :comparison_expr, [left, op, right]
      lhs = parse_comparable(left)
      rhs = parse_comparable(right)

      case op.text
      when "=="
        EqExpression.new(pair, lhs, rhs)
      when "!="
        NeExpression.new(pair, lhs, rhs)
      when "<="
        LeExpression.new(pair, lhs, rhs)
      when ">="
        GeExpression.new(pair, lhs, rhs)
      when "<"
        LtExpression.new(pair, lhs, rhs)
      when ">"
        GtExpression.new(pair, lhs, rhs)
      else
        raise "unexpected comparison operator #{op.text.inspect}"
      end
    in :test_expr, [not_expr, test_expr]
      LogicalNotExpression.new(not_expr, parse_test_expression(test_expr))
    in :test_expr, [test_expr]
      parse_test_expression(test_expr)
    else
      raise "expected a basic expression"
    end
  end

  def parse_test_expression(pair)
    case pair
    in :rel_query, children
      RelativeQueryExpression(pair, children.map { |child| parse_segment(child) })
    in :root_query, children
      RootQueryExpression(pair, children.map { |child| parse_segment(child) })
    in :function_expr, [name, *rest]
      func_name = name.text
      func = self::FUNCTION_EXTENSIONS[func_name]
      args = rest.map { |pair| parse_function_argument(pair) }
      assert_well_typed(name, func_name, func, args)
      FunctionExpression.new(pair, func_name, args, func)
    else
      raise "expected a test expression"
    end
  end

  def parse_comparable(pair)
    case pair
    in :number, _
      parse_number(pair)
    in :double_quoted, _
      StringLiteral.new(pair, unescape(pair.text, '"'))
    in :single_quoted, _
      StringLiteral.new(pair, unescape(pair.text, "'"))
    in :true_literal, _
      BooleanLiteral.new(pair, true)
    in :false_literal, _
      BooleanLiteral.new(pair, false)
    in :null, _
      NullLiteral(pair)
    in :rel_singular_query, children
      RelativeQueryExpression(pair, children.map { |child| parse_segment(child) })
    in :abs_singular_query, children
      RootQueryExpression(pair, children.map { |child| parse_segment(child) })
    in :function_expr, [name, *rest]
      func_name = name.text
      func = self::FUNCTION_EXTENSIONS[func_name]

      unless func.class::RETURN_TYPE == :value_expression
        raise "result of #{func_name} is not comparable"
      end

      args = rest.map { |pair| parse_function_argument(pair) }
      assert_well_typed(name, func_name, func, args)
      FunctionExpression.new(pair, func_name, args, func)
    else
      raise "expected a comparable"
    end
  end

  def parse_number(pair)
    case pair
    in :number, [] | [[:int, _]]
      IntegerLiteral.new(pair, pair.text.to_i)
    in :number, [[:int, _], [:frac, _], *]
      FloatLiteral.new(pair, pair.text.to_f)
    in :number, [[:int, _], [:exp, _]]
      if pair.children.last.text.include?("-")
        FloatLiteral(pair, pair.text.to_f)
      else
        IntegerLiteral(pair, pair.text.to_f.to_i)
      end
    else
      raise "expected a number"
    end
  end

  def parse_function_argument(pair)
    case pair
    in :number, _
      parse_number(pair)
    in :double_quoted, _
      StringLiteral.new(pair, unescape(pair.text, '"'))
    in :single_quoted, _
      StringLiteral.new(pair, unescape(pair.text, "'"))
    in :true_literal, _
      BooleanLiteral.new(pair, true)
    in :false_literal, _
      BooleanLiteral.new(pair, false)
    in :null, _
      NullLiteral(pair)
    in :rel_singular_query, children
      RelativeQueryExpression(pair, children.map { |child| parse_segment(child) })
    in :abs_singular_query, children
      RootQueryExpression(pair, children.map { |child| parse_segment(child) })
    in :function_expr, [name, *rest]
      func_name = name.text
      func = self::FUNCTION_EXTENSIONS[func_name]
      args = rest.map { |pair| parse_function_argument(pair) }
      assert_well_typed(name, func_name, func, args)
      FunctionExpression.new(pair, func_name, args, func)
    in :logical_or_expression, _
      parse_logical_or_expression(pair, func_expr: true)
    in :logical_and_expression, _
      parse_logical_and_expression(pair, func_expr: true)
    else
      raise "unexpected function argument #{pair.text.inspect}"
    end
  end

  def i_json_int(pair)
    i = pair.text.to_i
    raise "index out of range" if i.nil? || i < self::MIN_INT_INDEX || i > self::MAX_INT_INDEX

    i
  end

  def assert_well_typed(token, func_name, func_args, func)
  end
end
