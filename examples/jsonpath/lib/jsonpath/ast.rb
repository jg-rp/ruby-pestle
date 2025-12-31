# frozen_string_literal: true

# Abstract syntax tree nodes for a JSONPath engine parsed with Pest for Ruby.
module JSONPathPest
  FilterContext = Data.define(:current, :root)

  ChildSegment = Data.define(:token, :selectors) do
    def to_s = "[#{selectors.map(&:to_s).join(", ")}]"

    def resolve(nodes)
      rv = []
      nodes.each do |node|
        selectors.each do |selector|
          rv.concat(selector.resolve(node))
        end
      end
      rv
    end
  end

  DescendantSegment = Data.define(:token, :selectors) do
    def to_s = "..[#{selectors.map(&:to_s).join(", ")}]"

    def resolve(nodes)
      rv = []
      nodes.each do |node|
        visit(node).each do |descendant|
          selectors.each do |selector|
            rv.concat(selector.resolve(descendant))
          end
        end
      end
      rv
    end

    private

    def visit(node, depth = 1)
      rv = [node]

      if node.value.is_a?(Array)
        node.value.each_with_index do |value, i|
          child = JSONPathNode.new(value, [node.location, i], node.root)
          rv.concat(visit(child, depth + 1))
        end
      elsif node.value.is_a?(Hash)
        node.value.each do |key, value|
          child = JSONPathNode.new(value, [node.location, key], node.root)
          rv.concat(visit(child, depth + 1))
        end
      end

      rv
    end
  end

  NameSelector = Data.define(:token, :name) do
    def to_s = JSONPathPest.canonical_string(name)

    def resolve(node)
      return [] unless node.value.is_a?(Hash) && node.value.key?(name)

      [node.new_child(node.value[name], name)]
    end
  end

  IndexSelector = Data.define(:token, :index) do
    def to_s = index.to_s

    def resolve(node)
      return [] unless node.value.is_a?(Array)

      norm_index = normalize(index, node.value.length)
      return [] if norm_index.negative? || norm_index >= node.value.length

      [node.new_child(node.value[index], norm_index)]
    end

    private

    def normalize(index, length) = index.negative? && length >= index.abs ? length + index : index
  end

  WildcardSelector = Data.define(:token) do
    def to_s = "*"

    def resolve(node)
      if node.value.is_a?(Hash)
        node.value.map { |k, v| node.new_child(v, k) }
      elsif node.value.is_a?(Array)
        node.value.map.with_index { |e, i| node.new_child(e, i) }
      else
        []
      end
    end
  end

  SliceSelector = Data.define(:token, :start, :stop, :step) do
    def to_s = "#{start || ""}:#{stop || ""}:#{step || 1}"

    def resolve(node)
      return [] unless node.value.is_a?(Array)

      length = node.value.length
      return [] if length.zero? || step.zero?

      normalized_start = if start.nil?
                           step.negative? ? length - 1 : 0
                         elsif start&.negative?
                           [length + (start || raise), 0].max
                         else
                           [start || raise, length - 1].min
                         end

      normalized_stop = if stop.nil?
                          step.negative? ? -1 : length
                        elsif stop&.negative?
                          [length + (stop || raise), -1].max
                        else
                          [stop || raise, length].min
                        end

      (normalized_start...normalized_stop).step(step).map { |i| node.new_child(node.value[i], i) }
    end
  end

  FilterSelector = Data.define(:token, :expression) do
    def to_s = "?#{expression}"

    def resolve(node)
      nodes = []

      if node.value.is_a?(Array)
        node.value.each_with_index do |e, i|
          context = FilterContext.new(e, node.root)
          nodes << node.new_child(e, i) if expression.evaluate(context)
        end
      elsif node.value.is_a?(Hash)
        node.value.each_pair do |k, v|
          context = FilterContext.new(v, node.root)
          nodes << node.new_child(v, k) if expression.evaluate(context)
        end
      end

      nodes
    end
  end

  FilterExpression = Data.define(:token, :expression) do
    def to_s = to_canonical_string(expression, 1)

    def evaluate(context) = truthy?(expression.evaluate(context))

    private

    def to_canonical_string(expression, parent_precedence)
      if expression.instance_of?(LogicalAndExpression)
        left = to_canonical_string(expression.left, 4)
        right = to_canonical_string(expression.right, 4)
        expr = "#{left} && #{right}"
        return parent_precedence >= 4 ? "(#{expr})" : expr
      end

      if expression.instance_of?(LogicalOrExpression)
        left = to_canonical_string(expression.left, 3)
        right = to_canonical_string(expression.right, 3)
        expr = "#{left} || #{right}"
        return parent_precedence >= 3 ? "(#{expr})" : expr
      end

      if expression.instance_of?(LogicalNotExpression)
        operand = to_canonical_string(expression.expression, 7)
        expr = "!#{operand}"
        return parent_precedence > 7 ? `(#{expr})` : expr
      end

      expression.to_s
    end
  end

  BooleanLiteral = Data.define(:token, :value) do
    def to_s = value.to_s

    def evaluate(context) = value
  end

  StringLiteral = Data.define(:token, :value) do
    def to_s = canonical_string(value)

    def evaluate(context) = value
  end

  IntegerLiteral = Data.define(:token, :value) do
    def to_s = value

    def evaluate(context) = value
  end

  FloatLiteral = Data.define(:token, :value) do
    def to_s = value

    def evaluate(context) = value
  end

  NullLiteral = Data.define(:token) do
    def to_s = "null"

    def evaluate(context) = nil
  end

  LogicalNotExpression = Data.define(:token, :expression) do
    def to_s = "!#{expression}"

    def evaluate(context) = !truthy?(expression.evaluate(context))
  end

  LogicalAndExpression = Data.define(:token, :left, :right) do
    def to_s = "#{left} && #{right}"

    def evaluate(context) = truthy?(left.evaluate(context)) && truthy?(right.evaluate(context))
  end

  LogicalOrExpression = Data.define(:token, :left, :right) do
    def to_s = "#{left} || #{right}"

    def evaluate(context) = truthy?(left.evaluate(context)) || truthy?(right.evaluate(context))
  end

  EqExpression = Data.define(:token, :left, :right) do
    def to_s = "#{left} == #{right}"

    def evaluate(context) = eq?(left.evaluate(context), right.evaluate(context))
  end

  NeExpression = Data.define(:token, :left, :right) do
    def to_s = "#{left} != #{right}"

    def evaluate(context) = !eq?(left.evaluate(context), right.evaluate(context))
  end

  LeExpression = Data.define(:token, :left, :right) do
    def to_s = "#{left} <= #{right}"

    def evaluate(context)
      lhs = left.evaluate(context)
      rhs = right.evaluate(context)
      eq?(lhs, rhs) || lt?(lhs, rhs)
    end
  end

  GeExpression = Data.define(:token, :left, :right) do
    def to_s = "#{left} >= #{right}"

    def evaluate(context)
      lhs = left.evaluate(context)
      rhs = right.evaluate(context)
      eq?(lhs, rhs) || lt?(rhs, lhs)
    end
  end

  LtExpression = Data.define(:token, :left, :right) do
    def to_s = "#{left} < #{right}"

    def evaluate(context) = lt?(left.evaluate(context), right.evaluate(context))
  end

  GtExpression = Data.define(:token, :left, :right) do
    def to_s = "#{left} > #{right}"

    def evaluate(context) = lt?(right.evaluate(context), left.evaluate(context))
  end

  RelativeQueryExpression = Data.define(:token, :query) do
    def to_s = "@#{query.to_s[1..]}"

    def evaluate(context)
      unless context.current.is_a?(Array) || context.current.is_a?(Hash)
        return @query.empty? ? context.current : JSONPathPest::NodeList.new
      end

      @query.find(context.current)
    end
  end

  RootQueryExpression = Data.define(:token, :query) do
    def to_s = query.to_s

    def evaluate(context) = query.find(context.root)
  end

  FunctionExpression = Data.define(:token, :name, :args, :func) do
    def to_s = "#{name}(#{args.map(&:to_s).join(", ")})"

    def evaluate(context)
      args_ = args.map { |arg| arg.evaluate(context) }
      unpacked_args = unpack_node_lists(args_)
      func.call(*unpacked_args)
    end

    private

    def unpack_node_lists(args_)
      unpacked_args = []
      args_.each_with_index do |arg, i|
        unless arg.is_a?(JSONPathPest::NodeList) && func.class::ARG_TYPES[i] != :nodes_expression
          unpacked_args << arg
          next
        end

        unpacked_args << case arg.length
                         when 0
                           :nothing
                         when 1
                           arg.first.value
                         else
                           arg
                         end
      end
      unpacked_args
    end
  end

  def self.truthy?(obj)
    return !obj.empty? if obj.is_a?(JSONPathPest::NodeList)
    return false if obj == :nothing

    obj != false
  end

  def self.eq?(left, right)
    left = left.first.value if left.is_a?(JSONPathPest::NodeList) && left.length == 1
    right = right.first.value if right.is_a?(JSONPathPest::NodeList) && right.length == 1

    right, left = left, right if right.is_a?(JSONPathPest::NodeList)

    if left.is_a? JSONPathPest::NodeList
      return left == right if right.is_a? JSONPathPest::NodeList
      return right == :nothing if left.empty?
      return left.first == right if left.length == 1

      return false
    end

    return true if left == :nothing && right == :nothing

    left == right
  end

  def self.lt?(left, right)
    left = left.first.value if left.is_a?(JSONPathPest::NodeList) && left.length == 1
    right = right.first.value if right.is_a?(JSONPathPest::NodeList) && right.length == 1
    return left < right if left.is_a?(String) && right.is_a?(String)
    return left < right if (left.is_a?(Integer) || left.is_a?(Float)) &&
                           (right.is_a?(Integer) || right.is_a?(Float))

    false
  end
end
