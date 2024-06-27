class TicketType < ApplicationRecord
  self.table_name = :ticket_type
  validates :description, :color_mapserv, :color_hex, presence: true

  def self.policy_class
    SystemOperatorPolicy
  end
end
