class DiffAndAlertJob < ApplicationJob
  queue_as :default

  def perform(snapshot_id)
    snapshot = Snapshot.find_by(id: snapshot_id)
    return unless snapshot

    Snapshots::DiffService.call(snapshot)
  rescue => e
    Rails.logger.error "[DiffAndAlertJob] Error for snapshot #{snapshot_id}: #{e.message}"
  end
end
