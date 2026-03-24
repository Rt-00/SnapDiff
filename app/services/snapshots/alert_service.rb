module Snapshots
  class AlertService
    def self.call(diff_report)
      new(diff_report).call
    end

    def initialize(diff_report)
      @report = diff_report
    end

    def call
      notify_slack   if slack_configured?
      notify_discord if discord_configured?
    end

    private

    def payload
      endpoint = @report.snapshot_b.endpoint
      {
        text: "[SnapDiff] Changes detected on *#{endpoint.name}*",
        attachments: [
          {
            color: "warning",
            title: "#{@report.total_changes} change(s) detected",
            text:  @report.summary,
            fields: [
              { title: "Project",  value: endpoint.project.name, short: true },
              { title: "Endpoint", value: endpoint.url,          short: true }
            ]
          }
        ]
      }
    end

    def notify_slack
      Faraday.post(ENV["SLACK_WEBHOOK_URL"], payload.to_json,
                   "Content-Type" => "application/json")
    rescue Faraday::Error => e
      Rails.logger.warn "[AlertService] Slack notification failed: #{e.message}"
    end

    def notify_discord
      discord_payload = { content: payload[:text] }
      Faraday.post(ENV["DISCORD_WEBHOOK_URL"], discord_payload.to_json,
                   "Content-Type" => "application/json")
    rescue Faraday::Error => e
      Rails.logger.warn "[AlertService] Discord notification failed: #{e.message}"
    end

    def slack_configured?
      ENV["SLACK_WEBHOOK_URL"].present?
    end

    def discord_configured?
      ENV["DISCORD_WEBHOOK_URL"].present?
    end
  end
end
