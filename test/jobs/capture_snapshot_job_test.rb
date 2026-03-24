require "test_helper"

class CaptureSnapshotJobTest < ActiveJob::TestCase
  setup do
    @endpoint = create(:endpoint, url: "https://api.example.com/test")
  end

  test "performs a snapshot capture" do
    stub_request(:get, @endpoint.url)
      .to_return(status: 200, body: '{"ok":true}', headers: {})

    assert_difference "Snapshot.count", 1 do
      CaptureSnapshotJob.perform_now(@endpoint.id)
    end
  end

  test "sets triggered_by to scheduled by default" do
    stub_request(:get, @endpoint.url)
      .to_return(status: 200, body: "{}", headers: {})

    CaptureSnapshotJob.perform_now(@endpoint.id)
    assert_equal "scheduled", Snapshot.last.triggered_by
  end

  test "accepts custom triggered_by" do
    stub_request(:get, @endpoint.url)
      .to_return(status: 200, body: "{}", headers: {})

    CaptureSnapshotJob.perform_now(@endpoint.id, triggered_by: "ci")
    assert_equal "ci", Snapshot.last.triggered_by
  end

  test "does nothing if endpoint not found" do
    assert_no_difference "Snapshot.count" do
      CaptureSnapshotJob.perform_now(99999)
    end
  end

  test "can be enqueued" do
    assert_enqueued_with(job: CaptureSnapshotJob, args: [ @endpoint.id ]) do
      CaptureSnapshotJob.perform_later(@endpoint.id)
    end
  end
end
