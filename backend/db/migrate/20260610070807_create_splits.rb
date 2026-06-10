class CreateSplits < ActiveRecord::Migration[8.1]
  def change
    create_table :splits, id: :bigint do |t|
      t.bigint  :expense_id,    null: false
      t.bigint  :user_id,       null: false
      t.integer :share_cents,   null: false
      t.integer :share_percent

      t.timestamps
    end

    add_index :splits, %i[expense_id user_id], unique: true
    add_index :splits, :expense_id

    add_foreign_key :splits, :expenses, column: :expense_id
    add_foreign_key :splits, :users,    column: :user_id

    add_check_constraint :splits, "share_cents >= 0", name: "chk_splits_share_cents_non_negative"
  end
end
