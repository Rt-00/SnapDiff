require "test_helper"

class DiffReportTest < ActiveSupport::TestCase
  test "valid diff report" do
    assert build(:diff_report).valid?
  end

  test "invalid without summary" do
    report = build(:diff_report, summary: nil)
    assert_not report.valid?
  end

  test "has_changes? returns false when empty diff" do
    report = build(:diff_report, diff_data: { added: [], removed: [], changed: [] })
    assert_not report.has_changes?
  end

  test "has_changes? returns true when there are changes" do
    report = build(:diff_report, diff_data: {
      added:   [ { path: "name", value: "Alice" } ],
      removed: [],
      changed: []
    })
    assert report.has_changes?
  end

  test "total_changes sums all change types" do
    report = build(:diff_report, diff_data: {
      added:   [ { path: "a" } ],
      removed: [ { path: "b" }, { path: "c" } ],
      changed: [ { path: "d" } ]
    })
    assert_equal 4, report.total_changes
  end

  test "total_changes returns 0 for empty diff" do
    report = build(:diff_report, diff_data: { added: [], removed: [], changed: [] })
    assert_equal 0, report.total_changes
  end

  test "belongs to snapshot_a" do
    assert_respond_to build(:diff_report), :snapshot_a
  end

  test "belongs to snapshot_b" do
    assert_respond_to build(:diff_report), :snapshot_b
  end
end
