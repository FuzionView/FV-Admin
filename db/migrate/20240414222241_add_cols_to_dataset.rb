class AddColsToDataset < ActiveRecord::Migration[7.1]
  def change
    add_column :datasets, :geometry_name, :string
    add_column :datasets, :layer_name, :string
  end
end
