class SysConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :system_configurations, id: false do |t|
      t.string :key, primary_key: true
      t.text :value
      t.timestamps
    end
  end
end
