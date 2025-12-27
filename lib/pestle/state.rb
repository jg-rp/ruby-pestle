# frozen_string_literal: true

module Pestle
  # Pest parser state.
  class ParserState
    attr_reader :text, :scanner, :rules, :user_stack, :tags, :atomic_depth

    def initialize(text, rules, start_pos: 0)
      @text = text
      @rules = rules

      @scanner = StringScanner.new(text)
      @pos_checkpoints = [] # : Array[Integer]

      @atomic_depth = 0
      @atomic_depth_checkpoints = [] # : Array[Integer]

      @tags = [] # : Array[String]

      @user_stack = [] # : Array[String]
      @user_stack_popped = [] # : Array[String]
      @user_stack_lengths = [] # : Array[[Integer, Integer]]
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
        @user_stack_popped.slice!(remained_count..) # steep:ignore
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
      popped = @user_stack.pop
      return nil if popped.nil?

      unless @user_stack_lengths.empty?
        remained_count = @user_stack_lengths.last[1]
        if @user_stack.length == remained_count
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
      # TODO: optimized SKIP rule
      whitespace_rule = @rules["WHITESPACE"]
      comment_rule = @rules["COMMENT"]

      return false unless whitespace_rule || comment_rule

      children = [] # : Array[Pestle::Pair]
      some = false

      # TODO: suppress failures
      loop do
        matched = false

        unless whitespace_rule.nil?
          if whitespace_rule.parse(self, children)
            some = true
            matched = true
            pairs.concat(children)
          end
          children.clear
        end

        unless comment_rule.nil?
          if comment_rule.parse(self, children)
            some = true
            matched = true
            pairs.concat(children)
          end
          children.clear
        end

        break unless matched
      end

      some
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
  end
end
