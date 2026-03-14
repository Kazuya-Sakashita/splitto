# frozen_string_literal: true

class AddPublicIdToMembers < ActiveRecord::Migration[8.1]
  def up
    add_column :members, :public_id, :string, limit: 26

    Member.reset_column_information

    Member.find_each do |member|
      member.update_columns(public_id: generate_public_id)
    end

    change_column_null :members, :public_id, false
    add_index :members, :public_id, unique: true
  end

  def down
    remove_index :members, :public_id
    remove_column :members, :public_id
  end

  private

  def generate_public_id
    loop do
      candidate = SecureRandom.base58(26)
      break candidate unless Member.exists?(public_id: candidate)
    end
  end
end
