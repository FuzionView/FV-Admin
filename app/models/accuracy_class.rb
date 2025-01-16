class AccuracyClass < ApplicationRecord
  self.table_name = :feature_accuracy_class
  validates :id, :name, presence: true

  def self.policy_class
    SystemOperatorPolicy
  end
end
