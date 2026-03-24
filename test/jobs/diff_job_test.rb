require "test_helper"

class DiffJobTest < ActiveJob::TestCase
  setup do
    @endpoint   = create(:endpoint)
    @snapshot_a = create(:snapshot, endpoint: @endpoint,
                         response_body: { "name" => "Alice" }, taken_at: 1.hour.ago)
    @snapshot_b = create(:snapshot, endpoint: @endpoint,
                         response_body: { "name" => "Bob" }, taken_at: Time.current)
  end

  test "creates a DiffReport for a snapshot with a previous" do
    assert_difference "DiffReport.count", 1 do
      DiffJob.perform_now(@snapshot_b.id)
    end
  end

  test "does nothing when snapshot not found" do
    assert_no_difference "DiffReport.count" do
      DiffJob.perform_now(99999)
    end
  end

  test "does nothing when no previous snapshot exists" do
    isolated_endpoint = create(:endpoint)
    snapshot = create(:snapshot, endpoint: isolated_endpoint)

    assert_no_difference "DiffReport.count" do
      DiffJob.perform_now(snapshot.id)
    end
  end

  test "can be enqueued" do
    assert_enqueued_with(job: DiffJob, args: [ @snapshot_b.id ]) do
      DiffJob.perform_later(@snapshot_b.id)
    end
  end
end
