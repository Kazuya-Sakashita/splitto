# frozen_string_literal: true

namespace :data_migrations do
  desc "Backfill groups.invite_token_expires_at in batches"
  task backfill_invite_token_expires_at: :environment do
    batch_size = ENV.fetch("BATCH_SIZE", 1_000).to_i

    Group.unscoped.where(invite_token_expires_at: nil).in_batches(of: batch_size) do |relation|
      relation.update_all(invite_token_expires_at: Time.current + 24.hours)
      sleep(0.05)
    end
  end
end
