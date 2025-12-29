# frozen_string_literal: true

require "test_helper"

class TestUserStack < Minitest::Spec
  make_my_diffs_pretty!

  def test_snapshot_empty_stack
    s = Pestle::ParserState.new("", {})

    assert(s.stack_empty?)
    s.checkpoint

    assert(s.stack_empty?)
    s.stack_push("a")
    s.stack_restore

    assert(s.stack_empty?)
  end

  def test_snapshot_twice
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_snapshot
    s.stack_snapshot
    s.stack_restore
    s.stack_restore

    assert_equal(["a"], s.user_stack)
  end

  def test_restore_without_snapshot
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_restore

    assert_empty(s.user_stack)
  end

  def test_snapshot_and_restore
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_push("b")
    s.stack_snapshot
    s.stack_push("c")
    s.stack_push("d")
    s.stack_restore

    assert_equal(%w[a b], s.user_stack)
  end

  def test_multiple_snapshots
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_snapshot
    s.stack_push("b")
    s.stack_snapshot
    s.stack_push("c")
    s.stack_restore

    assert_equal(%w[a b], s.user_stack)
    s.stack_restore

    assert_equal(%w[a], s.user_stack)
  end

  def test_drop_snapshot_discards_last_snapshot
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_snapshot
    s.stack_push("b")
    s.stack_snapshot
    s.stack_push("c")

    s.stack_drop_snapshot
    s.stack_restore

    assert_equal(%w[a], s.user_stack)
  end

  def test_interleaved_push_pop_with_snapshots
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_push("b")
    s.stack_snapshot
    s.stack_push("c")
    s.stack_pop
    s.stack_push("d")
    s.stack_restore

    assert_equal(%w[a b], s.user_stack)
  end

  def test_snapshot_pop_restore
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_snapshot
    s.stack_pop
    s.stack_restore

    assert_equal(%w[a], s.user_stack)
  end

  def test_snapshot_pop_push_restore
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_snapshot
    s.stack_pop
    s.stack_push("b")
    s.stack_restore

    assert_equal(%w[a], s.user_stack)
  end

  def test_snapshot_push_pop_restore
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_snapshot
    s.stack_push("b")
    s.stack_push("c")
    s.stack_pop
    s.stack_restore

    assert_equal(%w[a], s.user_stack)
  end

  def test_snapshot_push_drop
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_snapshot
    s.stack_push("b")
    s.stack_drop_snapshot

    assert_equal(%w[a b], s.user_stack)
  end

  def test_snapshot_pop_drop
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_push("b")
    s.stack_snapshot
    s.stack_pop
    s.stack_drop_snapshot

    assert_equal(%w[a], s.user_stack)
  end

  def test_ops
    s = Pestle::ParserState.new("", {})

    assert(s.stack_empty?)
    assert_nil(s.stack_peek)
    assert_nil(s.stack_pop)

    s.stack_push("a")

    refute_empty(s.user_stack)
    assert_equal("a", s.stack_peek)

    s.stack_push("b")

    refute_empty(s.user_stack)
    assert_equal("b", s.stack_peek)

    assert_equal("b", s.stack_pop)
    assert_equal("a", s.stack_peek)
  end

  def test_clear_no_snapshot
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_push("b")
    s.stack_push("c")
    s.stack_clear

    assert_empty(s.user_stack)
  end

  def test_clear_with_snapshot_restore
    s = Pestle::ParserState.new("", {})
    s.stack_push("a")
    s.stack_push("b")
    s.stack_snapshot
    s.stack_push("c")
    s.stack_push("d")
    s.stack_clear

    assert_empty(s.user_stack)

    s.stack_restore

    assert_equal(%w[a b], s.user_stack)
  end
end
