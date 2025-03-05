class FeatureStatus < ApplicationRecord
  self.table_name = :feature_status
  validates :id, :name, presence: true

  def self.policy_class
    SystemOperatorPolicy
  end
end
