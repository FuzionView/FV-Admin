class FeatureClass < ApplicationRecord
  self.table_name = :feature_class
  validates :name, :color_mapserv, :color_hex, presence: true

  def self.policy_class
    SystemOperatorPolicy
  end
end
