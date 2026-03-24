class Endpoint < ApplicationRecord
  HTTP_METHODS = %w[GET POST PUT PATCH DELETE HEAD OPTIONS].freeze

  belongs_to :project
  has_many :snapshots, dependent: :destroy
  belongs_to :baseline_snapshot, class_name: "Snapshot", optional: true

  validates :name, presence: true
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/.+/, message: "must be a valid HTTP/HTTPS URL" }
  validates :http_method, presence: true, inclusion: { in: HTTP_METHODS }

  serialize :headers, coder: JSON
  serialize :body, coder: JSON

  after_initialize :set_defaults

  scope :ordered, -> { order(created_at: :desc) }

  delegate :user, to: :project

  private

  def set_defaults
    self.http_method ||= "GET"
    self.headers ||= {}
    self.body ||= {}
  end
end
