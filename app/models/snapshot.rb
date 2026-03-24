class Snapshot < ApplicationRecord
  TRIGGERED_BY = %w[manual scheduled ci].freeze

  belongs_to :endpoint
  has_one :project, through: :endpoint
  has_one :user, through: :project
  has_many :diff_reports_as_a, class_name: "DiffReport", foreign_key: :snapshot_a_id, dependent: :destroy
  has_many :diff_reports_as_b, class_name: "DiffReport", foreign_key: :snapshot_b_id, dependent: :destroy

  validates :taken_at, presence: true
  validates :triggered_by, inclusion: { in: TRIGGERED_BY }

  serialize :response_body, coder: JSON

  before_destroy :clear_as_baseline
  before_validation :set_taken_at

  scope :ordered, -> { order(taken_at: :desc) }
  scope :recent,  -> { ordered.limit(20) }

  def display_name
    name.presence || "Snapshot ##{id}"
  end

  def success?
    status_code.to_s.start_with?("2")
  end

  private

  def clear_as_baseline
    Endpoint.where(baseline_snapshot_id: id).update_all(baseline_snapshot_id: nil)
  end

  def set_taken_at
    self.taken_at ||= Time.current
  end
end
