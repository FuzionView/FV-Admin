  class Ticket < ApplicationRecord
    attribute :geom, GeomAsString.new
    validates :geom, presence: { message: 'is required.' }
    # Add dataset_id.  Poll for status if there
    # Jim will add invalidate features if dataset changes
    # Datasets add updated_at, created_at
    # 1) Test ticket submitted. Waiting for response
    # 2) If success and number link to ticket viewer
    # 3) If error no link, user can see status field (ogr error message)

    def init_test_ticket
      publish_date = Time.zone.now
      self.ticket_no =  '123'
      self.publish_date = publish_date
      self.purge_date = publish_date + 1.day
      self.is_latest = true
      self.ticket_type = 'normal'
    end
end
