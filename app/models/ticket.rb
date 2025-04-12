class Ticket < ApplicationRecord
  TICKET_NO = 'TEST'
  attribute :geom, GeomAsString.new
  validates :geom, presence: { message: 'is required.' }
  belongs_to :dataset, optional: true
  has_one :ticket_dataset_status
  delegate :status, :feature_count, :attempt, :updated_at,
           to: :ticket_dataset_status, allow_nil: true

  def init_test_ticket
    publish_date = Time.zone.now
    self.ticket_no =  TICKET_NO + "-#{Time.current.to_i}"
    self.publish_date = publish_date
    self.purge_date = publish_date + 1.day
    self.is_latest = true
    self.ticket_type = 'normal'
  end
end
