FactoryBot.define do
  factory :split do
    association :expense
    association :user

    share_cents { 1000 }
    share_percent { nil }
  end
end
