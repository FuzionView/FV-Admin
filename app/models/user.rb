class User < ApplicationRecord
  belongs_to :owner
  normalizes :email_address, with: ->(email) { email.strip.downcase }
  validates :email_address, presence: true
  validates :email_address, email: true, allow_blank: true
end
