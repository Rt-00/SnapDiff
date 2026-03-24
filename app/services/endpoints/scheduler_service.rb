module Endpoints
  # Enqueues CaptureSnapshotJob for each endpoint that has a cron schedule
  # and is due to run (simple time-based check against last snapshot).
  class SchedulerService
    def self.call
      new.call
    end

    def call
      scheduled_endpoints.each do |endpoint|
        next unless due?(endpoint)

        CaptureSnapshotJob.perform_later(endpoint.id, triggered_by: "scheduled")
        Rails.logger.info "[SchedulerService] Enqueued capture for endpoint #{endpoint.id} (#{endpoint.name})"
      end
    end

    private

    def scheduled_endpoints
      Endpoint.where.not(schedule: [ nil, "" ])
    end

    def due?(endpoint)
      last = endpoint.snapshots.order(taken_at: :desc).first
      return true if last.nil?

      cron = Fugit.parse_cron(endpoint.schedule)
      return false unless cron

      next_run = cron.next_time(last.taken_at.utc)
      # Compare as Float (seconds since epoch) to avoid type issues with EtOrbi::EoTime
      Time.current.to_f >= next_run.to_f
    rescue => e
      Rails.logger.warn "[SchedulerService] Could not parse schedule '#{endpoint.schedule}': #{e.message}"
      false
    end
  end
end
