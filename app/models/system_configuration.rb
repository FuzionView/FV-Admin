class SystemConfiguration < ApplicationRecord
  def self.default
    find_or_create_by(id: 'default')
  end

  def self.policy_class
    SystemOperatorPolicy
  end
end
