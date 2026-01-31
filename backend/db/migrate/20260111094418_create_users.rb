class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :external_uid, null: false

      t.timestamps
    end

    add_index :users, :external_uid, unique: true
  end
end
