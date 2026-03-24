class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable

  has_many :projects, dependent: :destroy

  has_secure_token :api_token, length: 36

  def self.find_by_api_token(token)
    return nil if token.blank?
    find_by(api_token: token)
  end
end
