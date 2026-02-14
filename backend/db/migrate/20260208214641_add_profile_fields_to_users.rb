class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :public_id, :string, limit: 26
    add_column :users, :name, :string
    add_column :users, :email, :string
    add_column :users, :notify_email, :boolean, null: false, default: true
    add_column :users, :theme_mode, :string, null: false, default: "SYSTEM"

    add_index :users, :public_id, unique: true
    add_check_constraint :users, "theme_mode IN ('SYSTEM','LIGHT','DARK')", name: "chk_users_theme_mode"

    execute <<~SQL.squish
      UPDATE users
      SET public_id = LPAD(CAST(id AS CHAR), 26, '0')
      WHERE public_id IS NULL
    SQL

    change_column_null :users, :public_id, false
  end

  def down
    remove_check_constraint :users, name: "chk_users_theme_mode"
    remove_index :users, :public_id

    remove_column :users, :theme_mode
    remove_column :users, :notify_email
    remove_column :users, :email
    remove_column :users, :name
    remove_column :users, :public_id
  end
end
