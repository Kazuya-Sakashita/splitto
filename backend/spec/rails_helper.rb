# frozen_string_literal: true

require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

# ✅ spec/support 配下のヘルパーや shared_context を自動で読み込む
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

# DBスキーマが最新でない場合にテスト実行を止める
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # spec/fixtures を使う場合のみ有効（使わないなら削除してOK）
  config.fixture_paths = [Rails.root.join("spec/fixtures")]

  # ActiveRecord を使う一般的な設定：各exampleをトランザクションで囲む
  config.use_transactional_fixtures = true

  # spec/requests, spec/models などディレクトリから type を自動推論
  config.infer_spec_type_from_file_location!

  # Rails/不要なgemのスタックトレースを短くする
  config.filter_rails_from_backtrace!

  # request spec が HostAuthorization で 403 になるのを防ぐ（必要に応じて変更）
  config.before(:each, type: :request) do
    host! "localhost"
  end
end
