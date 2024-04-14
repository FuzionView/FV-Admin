class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.references :owner, null: false, foreign_key: true
      t.string :email_address, null: false
      t.timestamps
    end
  end
end
