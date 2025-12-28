# frozen_string_literal: true

module Pestle::Grammar
  # Base class for all Pest grammar expressions.
  class Expression
    attr_reader :tag # : String?

    def initialize(tag: nil)
      @tag = tag
    end

    # Try to match this expression at the current position defined by `state`.
    # Append new token pairs to `pairs`.
    # @return `True` if the match was successful, `False` otherwise.
    def parse(state, pairs) # rubocop: disable Lint/UnusedMethodArgument
      raise "all expressions must implement `parse: (ParserState, Array[Pair]) -> bool`"
    end

    # Return this expressions direct child expressions.
    def children
      raise "all expressions must implement `children: () -> Array[Expression]`"
    end

    def tag_s
      "#{@tag}=" unless @tag.nil?
    end

    def tree_view
      # (prefix, connector, class_name, inspect_value)
      nodes = [] # : Array[[String, String, String, String]]

      # @type var visit: ^(Expression, String, bool) -> void
      visit = lambda do |node, prefix, is_last|
        connector = if prefix.empty?
                      ""
                    elsif is_last
                      "└── "
                    else
                      "├── "
                    end

        nodes << [prefix, connector, node.class.to_s, node.to_s]
        child_prefix = prefix + (is_last ? "    " : "│   ")
        node.children.each_with_index do |child, i|
          last = i == node.children.length - 1
          visit.call(child, child_prefix, last)
        end
      end

      visit.call(self, "", true)

      widths = nodes.map { |prefix, connector, cls| (prefix + connector + cls).length }
      max_width = widths.max || 0

      lines = [] # : Array[String]
      nodes.zip(widths).each do |node, width|
        prefix, connector, cls, val = node
        left = prefix + connector + cls
        padding = " " * (max_width - (width || raise) + 4)
        lines << (left + padding + val)
      end

      lines.join("\n")
    end
  end

  # Base class for terminal expressions (those without children).
  class Terminal < Expression
    def children = []
  end
end
