module Snapshots
  class DiffService
    def self.call(snapshot)
      new(snapshot).call
    end

    def initialize(snapshot)
      @snapshot = snapshot
      @endpoint = snapshot.endpoint
    end

    def call
      previous = previous_snapshot
      return unless previous

      diff_data = compute_diff(previous.response_body, @snapshot.response_body)
      summary   = summarize(diff_data)

      report = DiffReport.create!(
        snapshot_a: previous,
        snapshot_b: @snapshot,
        diff_data:  diff_data,
        summary:    summary
      )

      Snapshots::AlertService.call(report) if report.has_changes?

      report
    end

    private

    def previous_snapshot
      @endpoint.snapshots
               .where.not(id: @snapshot.id)
               .order(taken_at: :desc)
               .first
    end

    def compute_diff(before, after)
      changes = Hashdiff.diff(
        normalize(before),
        normalize(after),
        use_lcs: false
      )

      { added: [], removed: [], changed: [] }.tap do |result|
        changes.each do |(op, path, *values)|
          entry = { path: path }
          case op
          when "+"  then result[:added]   << entry.merge(value: values[0])
          when "-"  then result[:removed] << entry.merge(value: values[0])
          when "~"  then result[:changed] << entry.merge(old: values[0], new: values[1])
          end
        end
      end
    end

    def normalize(value)
      case value
      when Hash  then value.transform_keys(&:to_s)
      when Array then value
      else            { "_value" => value }
      end
    end

    def summarize(diff_data)
      total = diff_data.values.sum(&:length)
      parts = []
      parts << "#{diff_data[:added].length} added"   if diff_data[:added].any?
      parts << "#{diff_data[:removed].length} removed" if diff_data[:removed].any?
      parts << "#{diff_data[:changed].length} changed" if diff_data[:changed].any?
      parts.empty? ? "No changes" : parts.join(", ")
    end
  end
end
