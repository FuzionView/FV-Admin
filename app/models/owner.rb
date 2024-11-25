class Owner < ApplicationRecord
  has_many :datasets, -> { order(:id) }, dependent: :destroy
  has_many :users, dependent: :destroy
  validates :name, presence: true
end
