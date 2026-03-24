class CaptureSnapshotJob < ApplicationJob
  queue_as :default

  def perform(endpoint_id, triggered_by: "scheduled")
    endpoint = Endpoint.find_by(id: endpoint_id)
    return unless endpoint

    result = Snapshots::CaptureService.new(
      endpoint:     endpoint,
      triggered_by: triggered_by
    ).call

    unless result.success?
      Rails.logger.warn "[CaptureSnapshotJob] Failed for endpoint #{endpoint_id}: #{result.error}"
    end
  end
end
