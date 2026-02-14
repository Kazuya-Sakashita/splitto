# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:public_id) { |n| format("01H%023d", n) }
    sequence(:external_uid) { |n| "user_external_uid_#{n}" }

    # いまの insert ログに出てたカラムに合わせて最低限
    theme_mode { "SYSTEM" }
    notify_email { true }

    # 必須でなければ nil でOK（DBが null許可なら）
    email { nil }
    name { nil }
  end
end
