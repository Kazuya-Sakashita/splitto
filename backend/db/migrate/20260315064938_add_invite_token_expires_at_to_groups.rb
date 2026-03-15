# frozen_string_literal: true

class AddInviteTokenExpiresAtToGroups < ActiveRecord::Migration[8.1]
  def change
    add_column :groups, :invite_token_expires_at, :datetime
  end
end
