class Dataset < ApplicationRecord
  belongs_to :owner
  validates :name, :source_dataset, :source_sql,
            :geometry_name, :layer_name, presence: true
  before_validation :set_sql_from_template, on: :create


  def set_sql_from_template
    sql_template = <<-END_SQL
   SELECT
       id,
       "#{geometry_name}" geom,
       null feature_class,
       null status_id,
       null size,
       null depth,
       null accuracy_value,
       null description
    FROM
      "#{layer_name}"
    END_SQL
    self.source_sql = sql_template
  end
end
