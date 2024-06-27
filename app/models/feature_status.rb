class FeatureStatus < ApplicationRecord
  self.table_name = :feature_status
  validates :status, presence: true
  def self.policy_class
    SystemOperatorPolicy
  end
end
