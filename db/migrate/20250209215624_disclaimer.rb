class Disclaimer < ActiveRecord::Migration[7.1]
  create_table :disclaimers, id: false do |t|
    t.string :id, primary_key: true
    t.text :disclaimer_text
    t.text :remote_url
    t.timestamps
  end
end
