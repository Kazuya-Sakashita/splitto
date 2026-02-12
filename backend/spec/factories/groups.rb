FactoryBot.define do
  factory :group do
    sequence(:public_id) { |n| format("01H%023d", n) }
    sequence(:name) { |n| "Group #{n}" }
    currency { "JPY" }
    sequence(:invite_token) { |n| "invite_token_#{n}" }
  end
end
