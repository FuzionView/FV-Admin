class Owner < ApplicationRecord
  has_many :datasets
  validates :name, presence: true
end
