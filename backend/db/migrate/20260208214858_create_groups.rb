class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups, id: :bigint do |t|
      t.string :public_id,    null: false, limit: 26
      t.string :name,         null: false
      t.string :currency,     null: false, default: "JPY"
      t.string :invite_token, null: false

      t.timestamps
    end

    add_index :groups, :public_id, unique: true
    add_index :groups, :invite_token, unique: true
  end
end
