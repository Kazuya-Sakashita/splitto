class CreateMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :members, id: :bigint do |t|
      t.bigint :group_id, null: false
      t.bigint :user_id,  null: false

      t.string :role, null: false, default: "MEMBER"

      t.boolean  :active,    null: false, default: true
      t.datetime :joined_at, null: false
      t.datetime :left_at

      t.timestamps
    end

    add_index :members, %i[group_id user_id], unique: true
    add_index :members, :group_id

    add_foreign_key :members, :groups, column: :group_id
    add_foreign_key :members, :users,  column: :user_id

    add_check_constraint :members, "role IN ('OWNER','MEMBER')", name: "chk_members_role"
  end
end
