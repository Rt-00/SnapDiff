class DiffJob < ApplicationJob
  queue_as :default

  def perform(snapshot_id)
    snapshot = Snapshot.find_by(id: snapshot_id)
    return unless snapshot

    Snapshots::DiffService.call(snapshot)
  rescue => e
    Rails.logger.error "[DiffJob] Error for snapshot #{snapshot_id}: #{e.message}"
    raise
  end
end
