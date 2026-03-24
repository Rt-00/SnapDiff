class Endpoint < ApplicationRecord
  HTTP_METHODS = %w[GET POST PUT PATCH DELETE HEAD OPTIONS].freeze

  # Private/reserved IPv4 ranges (RFC 1918, loopback, link-local, etc.)
  PRIVATE_IP_RANGES = [
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7")
  ].freeze

  belongs_to :project
  has_many :snapshots, dependent: :destroy
  belongs_to :baseline_snapshot, class_name: "Snapshot", optional: true

  validates :name, presence: true
  validates :url, presence: true, format: { with: /\Ahttps?:\/\/.+/, message: "must be a valid HTTP/HTTPS URL" }
  validates :http_method, presence: true, inclusion: { in: HTTP_METHODS }
  validate :url_not_internal_network

  serialize :headers, coder: JSON
  serialize :body, coder: JSON

  after_initialize :set_defaults

  scope :ordered, -> { order(created_at: :desc) }

  delegate :user, to: :project

  private

  def url_not_internal_network
    return if url.blank?

    uri = URI.parse(url)
    host = uri.host.to_s.downcase

    if host.match?(/\A(localhost|.*\.local|.*\.internal|metadata\.google\.internal)\z/)
      errors.add(:url, "cannot point to internal network"); return
    end

    ip = IPAddr.new(host)
    if PRIVATE_IP_RANGES.any? { |range| range.include?(ip) }
      errors.add(:url, "cannot point to internal network")
    end
  rescue URI::InvalidURIError, IPAddr::InvalidAddressError
    nil # URL format validation handles malformed URLs
  end

  def set_defaults
    self.http_method ||= "GET"
    self.headers ||= {}
    self.body ||= {}
  end
end
