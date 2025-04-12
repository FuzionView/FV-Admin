class Owner < ApplicationRecord
  attribute :service_area, GeomAsString.new
  has_many :datasets, -> { order(:id) }, dependent: :destroy
  has_many :service_authentication_configurations, -> { order(:id) }, dependent: :destroy
  has_many :users, dependent: :destroy
  validates :name, presence: true
end
