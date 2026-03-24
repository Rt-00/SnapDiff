class Snapshot < ApplicationRecord
  TRIGGERED_BY = %w[manual scheduled ci].freeze

  belongs_to :endpoint
  has_one :project, through: :endpoint
  has_one :user, through: :project

  validates :taken_at, presence: true
  validates :triggered_by, inclusion: { in: TRIGGERED_BY }

  serialize :response_body, coder: JSON

  before_validation :set_taken_at

  scope :ordered, -> { order(taken_at: :desc) }
  scope :recent,  -> { ordered.limit(20) }

  def success?
    status_code.to_s.start_with?("2")
  end

  private

  def set_taken_at
    self.taken_at ||= Time.current
  end
end
