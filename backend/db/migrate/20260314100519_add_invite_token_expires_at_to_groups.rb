# frozen_string_literal: true

class AddInviteTokenExpiresAtToGroups < ActiveRecord::Migration[8.1]
  def up
    add_column :groups, :invite_token_expires_at, :datetime

    execute <<~SQL.squish
      UPDATE `groups`
      SET invite_token_expires_at = DATE_ADD(UTC_TIMESTAMP(), INTERVAL 24 HOUR)
      WHERE invite_token_expires_at IS NULL
    SQL

    change_column_null :groups, :invite_token_expires_at, false
  end

  def down
    remove_column :groups, :invite_token_expires_at
  end
end
