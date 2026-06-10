class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses, id: :bigint do |t|
      t.string  :public_id,       null: false, limit: 26
      t.bigint  :group_id,        null: false
      t.bigint  :paid_by_id,      null: false
      t.bigint  :created_by_id,   null: false
      t.integer :amount_cents,    null: false
      t.date    :paid_on,         null: false
      t.string  :category
      t.text    :note
      t.string  :split_type,      null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :expenses, :public_id, unique: true
    add_index :expenses, %i[group_id paid_on]
    add_index :expenses, %i[group_id deleted_at]
    add_index :expenses, :paid_by_id

    add_foreign_key :expenses, :groups, column: :group_id
    add_foreign_key :expenses, :users,  column: :paid_by_id
    add_foreign_key :expenses, :users,  column: :created_by_id

    add_check_constraint :expenses,
                         "split_type IN ('EQUAL_ALL','EQUAL_SELECTED','AMOUNT','PERCENT')",
                         name: "chk_expenses_split_type"
    add_check_constraint :expenses, "amount_cents > 0", name: "chk_expenses_amount_positive"
  end
end
