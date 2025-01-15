class FeatureStatus < ApplicationRecord
  self.table_name = :feature_status
  validates :name, presence: true
  def self.policy_class
    SystemOperatorPolicy
  end
end
