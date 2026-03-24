require "test_helper"

class Snapshots::AlertServiceTest < ActiveSupport::TestCase
  setup do
    @endpoint  = create(:endpoint)
    @snap_a    = create(:snapshot, endpoint: @endpoint, response_body: { "a" => 1 }, taken_at: 1.hour.ago)
    @snap_b    = create(:snapshot, endpoint: @endpoint, response_body: { "b" => 2 }, taken_at: Time.current)
    @report    = DiffReport.create!(
      snapshot_a: @snap_a,
      snapshot_b: @snap_b,
      diff_data:  { added: [{ path: "b", value: 2 }], removed: [{ path: "a", value: 1 }], changed: [] },
      summary:    "1 added, 1 removed"
    )
  end

  test "does not call Slack when SLACK_WEBHOOK_URL is not set" do
    with_env("SLACK_WEBHOOK_URL" => nil) do
      stub_request(:post, "https://hooks.slack.com/test")
      Snapshots::AlertService.call(@report)
      assert_not_requested :post, "https://hooks.slack.com/test"
    end
  end

  test "sends Slack notification when SLACK_WEBHOOK_URL is set" do
    with_env("SLACK_WEBHOOK_URL" => "https://hooks.slack.com/test") do
      stub_request(:post, "https://hooks.slack.com/test")
        .to_return(status: 200, body: "ok")
      Snapshots::AlertService.call(@report)
      assert_requested :post, "https://hooks.slack.com/test"
    end
  end

  test "sends Discord notification when DISCORD_WEBHOOK_URL is set" do
    with_env("DISCORD_WEBHOOK_URL" => "https://discord.com/api/webhooks/test") do
      stub_request(:post, "https://discord.com/api/webhooks/test")
        .to_return(status: 204)
      Snapshots::AlertService.call(@report)
      assert_requested :post, "https://discord.com/api/webhooks/test"
    end
  end

  test "does not raise when Slack request fails" do
    with_env("SLACK_WEBHOOK_URL" => "https://hooks.slack.com/test") do
      stub_request(:post, "https://hooks.slack.com/test")
        .to_raise(Faraday::ConnectionFailed.new("refused"))
      assert_nothing_raised { Snapshots::AlertService.call(@report) }
    end
  end

  private

  def with_env(vars)
    old_values = vars.keys.each_with_object({}) { |k, h| h[k] = ENV[k] }
    vars.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old_values.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end
end
