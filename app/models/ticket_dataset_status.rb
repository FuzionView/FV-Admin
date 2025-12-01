class TicketDatasetStatus < ApplicationRecord
  self.primary_key = [ :ticket_id, :dataset_id ]
  self.table_name = :ticket_dataset_status
  # belongs_to :ticket, class_name: 'Ticket', foreign_key: :ticket_id
  # belongs_to :dataset
end
