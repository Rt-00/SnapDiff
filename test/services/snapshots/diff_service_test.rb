require "test_helper"

class Snapshots::DiffServiceTest < ActiveSupport::TestCase
  setup do
    @endpoint   = create(:endpoint)
    @snapshot_a = create(:snapshot, endpoint: @endpoint,
                         response_body: { "id" => 1, "name" => "Alice", "age" => 30 },
                         taken_at: 1.hour.ago)
    @snapshot_b = create(:snapshot, endpoint: @endpoint,
                         response_body: { "id" => 1, "name" => "Bob", "email" => "bob@example.com" },
                         taken_at: Time.current)
  end

  test "returns nil when no previous snapshot exists" do
    endpoint = create(:endpoint)
    snapshot = create(:snapshot, endpoint: endpoint)
    result = Snapshots::DiffService.call(snapshot)
    assert_nil result
  end

  test "creates a DiffReport comparing previous and current snapshot" do
    assert_difference "DiffReport.count", 1 do
      Snapshots::DiffService.call(@snapshot_b)
    end
  end

  test "detects added fields" do
    report = Snapshots::DiffService.call(@snapshot_b)
    added_paths = (report.diff_data["added"] || report.diff_data[:added] || []).map { |c| c["path"] || c[:path] }
    assert_includes added_paths, "email"
  end

  test "detects removed fields" do
    report = Snapshots::DiffService.call(@snapshot_b)
    removed_paths = (report.diff_data["removed"] || report.diff_data[:removed] || []).map { |c| c["path"] || c[:path] }
    assert_includes removed_paths, "age"
  end

  test "detects changed fields" do
    report = Snapshots::DiffService.call(@snapshot_b)
    changed_paths = (report.diff_data["changed"] || report.diff_data[:changed] || []).map { |c| c["path"] || c[:path] }
    assert_includes changed_paths, "name"
  end

  test "generates a human-readable summary" do
    report = Snapshots::DiffService.call(@snapshot_b)
    assert report.summary.include?("added") || report.summary.include?("removed") || report.summary.include?("changed")
  end

  test "reports no changes for identical snapshots" do
    # Use an isolated endpoint so setup snapshots don't interfere
    isolated_endpoint = create(:endpoint)
    same_body = { "id" => 1, "name" => "Alice" }
    create(:snapshot, endpoint: isolated_endpoint, response_body: same_body, taken_at: 2.hours.ago)
    snap_b = create(:snapshot, endpoint: isolated_endpoint, response_body: same_body, taken_at: 1.minute.ago)
    report = Snapshots::DiffService.call(snap_b)
    assert_equal "No changes", report.summary
    assert_not report.has_changes?
  end
end
