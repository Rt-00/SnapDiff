module Snapshots
  class CaptureService
    Result = Struct.new(:snapshot, :error, keyword_init: true) do
      def success? = error.nil?
    end

    def initialize(endpoint:, triggered_by: "manual")
      @endpoint = endpoint
      @triggered_by = triggered_by
    end

    def call
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      response = http_client.run_request(
        @endpoint.http_method.downcase.to_sym,
        @endpoint.url,
        body_payload,
        headers_hash
      )
      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round

      snapshot = @endpoint.snapshots.create!(
        response_body: parse_body(response.body),
        status_code:   response.status,
        response_time_ms: elapsed_ms,
        taken_at:      Time.current,
        triggered_by:  @triggered_by
      )

      DiffAndAlertJob.perform_later(snapshot.id)

      Result.new(snapshot: snapshot)
    rescue Faraday::Error => e
      Result.new(error: "HTTP request failed: #{e.message}")
    rescue ActiveRecord::RecordInvalid => e
      Result.new(error: "Could not save snapshot: #{e.message}")
    end

    private

    def http_client
      Faraday.new do |f|
        f.options.timeout = 30
        f.options.open_timeout = 10
        f.adapter Faraday.default_adapter
      end
    end

    def headers_hash
      base = { "Accept" => "application/json" }
      base.merge(@endpoint.headers.to_h)
    end

    def body_payload
      return nil if %w[GET HEAD DELETE OPTIONS].include?(@endpoint.http_method.upcase)
      body = @endpoint.body.to_h
      body.empty? ? nil : body.to_json
    end

    def parse_body(raw)
      JSON.parse(raw)
    rescue JSON::ParserError
      { "_raw" => raw }
    end
  end
end
