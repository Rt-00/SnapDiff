class DiffReport < ApplicationRecord
  belongs_to :snapshot_a, class_name: "Snapshot"
  belongs_to :snapshot_b, class_name: "Snapshot"

  serialize :diff_data, coder: JSON

  validates :summary, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  def has_changes?
    return false if diff_data.blank?
    data = diff_data.is_a?(Hash) ? diff_data : {}
    added   = (data["added"]   || data[:added]   || []).length
    removed = (data["removed"] || data[:removed] || []).length
    changed = (data["changed"] || data[:changed] || []).length
    (added + removed + changed) > 0
  end

  def total_changes
    return 0 if diff_data.blank?
    data = diff_data.is_a?(Hash) ? diff_data : {}
    [ data["added"]   || data[:added]   || [],
      data["removed"] || data[:removed] || [],
      data["changed"] || data[:changed] || [] ].sum(&:length)
  end
end
