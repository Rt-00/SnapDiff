require "test_helper"

class SnapshotTest < ActiveSupport::TestCase
  test "valid snapshot" do
    assert build(:snapshot).valid?
  end

  test "invalid without taken_at" do
    # taken_at is auto-set by before_validation, so we force nil after build
    snapshot = build(:snapshot)
    snapshot.taken_at = nil
    snapshot.instance_variable_set(:@skip_set_taken_at, true)
    # bypass callback for test
    snapshot.class.skip_callback(:validation, :before, :set_taken_at, raise: false)
    assert_not snapshot.valid?
    snapshot.class.set_callback(:validation, :before, :set_taken_at)
  end

  test "invalid with unknown triggered_by" do
    snapshot = build(:snapshot, triggered_by: "unknown")
    assert_not snapshot.valid?
  end

  test "all valid triggered_by values" do
    %w[manual scheduled ci].each do |val|
      snapshot = build(:snapshot, triggered_by: val)
      assert snapshot.valid?, "Expected '#{val}' to be valid"
    end
  end

  test "success? returns true for 2xx" do
    assert build(:snapshot, status_code: 200).success?
    assert build(:snapshot, status_code: 201).success?
  end

  test "success? returns false for non-2xx" do
    assert_not build(:snapshot, status_code: 404).success?
    assert_not build(:snapshot, status_code: 500).success?
  end

  test "belongs to endpoint" do
    assert_respond_to build(:snapshot), :endpoint
  end

  test "taken_at is set automatically before validation" do
    snapshot = build(:snapshot, taken_at: nil)
    snapshot.valid?
    assert_not_nil snapshot.taken_at
  end
end
