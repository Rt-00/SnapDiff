class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Generate UUID v7 (time-ordered) for all primary keys
  before_create { self.id ||= SecureRandom.uuid_v7 }

  # UUID v7 is time-ordered, but explicit created_at ordering is clearer
  self.implicit_order_column = "created_at"
end
