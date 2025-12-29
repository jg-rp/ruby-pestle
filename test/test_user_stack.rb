# frozen_string_literal: true

require "test_helper"

class TestUserStack < Minitest::Spec
  make_my_diffs_pretty!

  def test_snapshot_empty_stack
    s = Pestle::ParserState.new("", {})

    assert(s.stack_empty?)
    s.checkpoint

    assert(s.stack_empty?)
    s.stack_push("0")
    s.stack_restore

    assert(s.stack_empty?)
  end

  # TODO:
end
