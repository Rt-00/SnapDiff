require "test_helper"

class Endpoints::SchedulerServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @endpoint_with_schedule    = create(:endpoint, schedule: "*/5 * * * *") # every 5 min
    @endpoint_without_schedule = create(:endpoint, schedule: nil)
  end

  test "only considers endpoints with a schedule" do
    assert_enqueued_jobs 1 do
      Endpoints::SchedulerService.call
    end
    # The endpoint without a schedule should not have triggered a job
    jobs = enqueued_jobs.select { |j| j[:job] == CaptureSnapshotJob }
    assert_equal 1, jobs.size
    assert_equal @endpoint_with_schedule.id, jobs.first[:args].first
  end

  test "enqueues job when endpoint has never been captured" do
    assert_enqueued_jobs 1 do
      Endpoints::SchedulerService.call
    end
  end

  test "skips endpoints without a schedule" do
    Endpoint.update_all(schedule: nil)
    assert_no_enqueued_jobs do
      Endpoints::SchedulerService.call
    end
  end

  test "does not enqueue when last snapshot was recent" do
    # Create a snapshot just 1 minute ago — shouldn't be due yet for a 5-minute schedule
    create(:snapshot, endpoint: @endpoint_with_schedule, taken_at: 1.minute.ago)

    assert_no_enqueued_jobs do
      Endpoints::SchedulerService.call
    end
  end

  test "due? returns true when last snapshot is old enough" do
    # Test the scheduling logic directly via a new endpoint with an old snapshot
    ep = create(:endpoint, schedule: "*/5 * * * *")
    create(:snapshot, endpoint: ep, taken_at: 1.hour.ago, triggered_by: "manual")
    svc = Endpoints::SchedulerService.new
    assert svc.send(:due?, ep), "Expected endpoint to be due after 1 hour"
  end

  test "handles invalid cron expression gracefully" do
    endpoint = create(:endpoint, schedule: "not-a-cron")
    assert_nothing_raised { Endpoints::SchedulerService.call }
  end
end
