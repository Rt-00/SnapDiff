class DiffAndAlertJob < ApplicationJob
  queue_as :default

  def perform(snapshot_id)
    snapshot = Snapshot.find_by(id: snapshot_id)
    return unless snapshot

    report = Snapshots::DiffService.call(snapshot)

    if report&.has_changes?
      Snapshots::AlertService.call(report)
    end
  rescue => e
    Rails.logger.error "[DiffAndAlertJob] Error for snapshot #{snapshot_id}: #{e.message}"
    raise # re-raise for Solid Queue retry mechanism
  end
end
