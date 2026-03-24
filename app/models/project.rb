class Project < ApplicationRecord
  belongs_to :user
  has_many :endpoints, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :user_id, message: "already exists in your account" }

  scope :ordered, -> { order(created_at: :desc) }
end
