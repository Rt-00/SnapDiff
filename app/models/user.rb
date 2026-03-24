class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :projects, dependent: :destroy

  before_create :generate_api_token

  def regenerate_api_token!
    update!(api_token: self.class.generate_unique_token)
  end

  def self.find_by_api_token(token)
    return nil if token.blank?
    find_by(api_token: token)
  end

  private

  def generate_api_token
    self.api_token ||= self.class.generate_unique_token
  end

  def self.generate_unique_token
    loop do
      token = SecureRandom.hex(32)
      break token unless exists?(api_token: token)
    end
  end
end
