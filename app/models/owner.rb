class Owner < ApplicationRecord
  has_many :datasets
  has_many :users
  validates :name, presence: true
end
