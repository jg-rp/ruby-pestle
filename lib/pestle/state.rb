# frozen_string_literal: true

module Pestle
  # Pest parser state.
  class ParserState
    attr_reader :text, :scanner, :rules, :user_stack, :tags, :atomic_depth, :rule_stack,
                :furthest_pos, :furthest_expected, :furthest_unexpected, :furthest_rules,
                :neg_pred_stack

    # @param text [String] Source text to be parsed into nested token pairs.
    # @param start_pos [Integer] A byte offset from which to start scanning `text`.
    def initialize(text, rules, start_pos: 0)
      @text = text
      @rules = rules

      @scanner = StringScanner.new(text)
      @scanner.pos = start_pos
      @pos_checkpoints = []

      @atomic_depth = 0
      @atomic_depth_checkpoints = []

      # A stack of grammar-defined expression tags.
      @tags = []

      @user_stack = []
      @user_stack_popped = []
      @user_stack_lengths = []

      # Furthest failure tracking for error reporting.
      @rule_stack = []
      @neg_pred_stack = []
      @furthest_pos = -1
      @furthest_rules = []
      @furthest_expected = {}
      @furthest_unexpected = {}
    end

    def checkpoint
      stack_snapshot
      @atomic_depth_checkpoints << @atomic_depth
      @pos_checkpoints << @scanner.pos
    end

    def ok
      stack_drop_snapshot
      @atomic_depth_checkpoints.pop
      @pos_checkpoints.pop
    end

    def restore
      stack_restore
      @atomic_depth = @atomic_depth_checkpoints.pop || raise
      @scanner.pos = @pos_checkpoints.pop || raise
    end

    def stack_snapshot
      @user_stack_lengths << [@user_stack.length, @user_stack.length]
    end

    def stack_drop_snapshot
      return if @user_stack_lengths.empty?

      item_count, remained_count = @user_stack_lengths.pop || raise
      @user_stack_popped.slice!((item_count - remained_count)..) # steep:ignore
    end

    def stack_restore
      if @user_stack_lengths.empty?
        @user_stack.clear
        return
      end

      item_count, remained_count = @user_stack_lengths.pop || raise

      if remained_count < @user_stack.length
        @user_stack.slice!(remained_count..) # steep:ignore
      end

      return unless item_count > remained_count

      rewind_count = item_count - remained_count
      new_size = @user_stack_popped.length - rewind_count
      recovered = @user_stack_popped[new_size..]&.reverse!
      @user_stack_popped.slice!(new_size..) # steep:ignore
      @user_stack.concat(recovered || raise)
    end

    def stack_empty?
      @user_stack.empty?
    end

    def stack_push(value)
      @user_stack << value
    end

    def stack_pop
      size = @user_stack.length
      popped = @user_stack.pop
      return nil if popped.nil?

      unless @user_stack_lengths.empty?
        remained_count = @user_stack_lengths.last[1]
        if size == remained_count
          @user_stack_lengths.last[1] -= 1
          @user_stack_popped << popped
        end
      end
      popped
    end

    def stack_peek
      @user_stack.last
    end

    def stack_peek_slice(start, stop)
      @user_stack[(start || 0)...(stop || @user_stack.length)] || []
    end

    def stack_clear
      return if @user_stack.empty?

      if @user_stack_lengths.empty?
        @user_stack_popped.clear
        @user_stack_lengths.clear
      else
        @user_stack_lengths.last[1] = 0
        @user_stack_popped.concat(@user_stack.reverse)
      end

      @user_stack = []
    end

    def parse_trivia(pairs)
      return false if @atomic_depth.positive?

      # TODO: optimized SKIP rule
      whitespace_rule = @rules["WHITESPACE"]
      comment_rule = @rules["COMMENT"]

      return false unless whitespace_rule || comment_rule

      children = [] # : Array[Pestle::Pair]

      loop do
        matched = false

        unless whitespace_rule.nil?
          if whitespace_rule.parse(self, children)
            matched = true
            pairs.concat(children)
          end
          children.clear
        end

        unless comment_rule.nil?
          if comment_rule.parse(self, children)
            matched = true
            pairs.concat(children)
          end
          children.clear
        end

        break unless matched
      end

      true # Always succeed
    end

    def with_tag(name)
      @tags << name
      yield
      @tags.pop
    end

    def atomic
      @atomic_depth_checkpoints << @atomic_depth
      @atomic_depth += 1
      yield
      @atomic_depth = @atomic_depth_checkpoints.pop || raise
    end

    def nonatomic
      @atomic_depth_checkpoints << @atomic_depth
      @atomic_depth = 0
      yield
      @atomic_depth = @atomic_depth_checkpoints.pop || raise
    end

    # Record terminal expression failures for error reporting.
    def track(label, matched)
      neg_pred_context = @neg_pred_stack.length.odd?

      return unless (neg_pred_context && matched) || (!neg_pred_context && !matched)

      rule_name = @rule_stack.last
      pos = neg_pred_context ? @neg_pred_stack.last : @scanner.pos

      if pos > @furthest_pos
        @furthest_pos = pos
        @furthest_rules = @rule_stack.dup
        if neg_pred_context
          @furthest_unexpected = { rule_name => [label] }
          @furthest_expected = {} # : Hash[String, Array[String]]
        else
          @furthest_unexpected = {} # : Hash[String, Array[String]]
          @furthest_expected = { rule_name => [label] }
        end
      elsif @scanner.pos == @furthest_pos
        target = neg_pred_context ? @furthest_unexpected : @furthest_expected

        if target.member?(rule_name)
          target[rule_name] << label
        else
          target[rule_name] = [label]
        end
      end
    end
  end
end
