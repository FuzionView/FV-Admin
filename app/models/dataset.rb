class Dataset < ApplicationRecord
  belongs_to :owner

  validates :name, :source_dataset, :source_sql, presence: true
end
