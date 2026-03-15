# frozen_string_literal: true

class ChangeInviteTokenExpiresAtOnGroupsToNotNull < ActiveRecord::Migration[8.1]
  class Group < ApplicationRecord
    self.table_name = "groups"
  end

  def up
    if Group.where(invite_token_expires_at: nil).exists?
      raise "Backfill not finished: groups.invite_token_expires_at still has NULL rows"
    end

    change_column_null :groups, :invite_token_expires_at, false
  end

  def down
    change_column_null :groups, :invite_token_expires_at, true
  end
end
