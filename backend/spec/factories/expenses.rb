FactoryBot.define do
  factory :expense do
    association :group
    association :paid_by, factory: :user
    association :created_by, factory: :user

    public_id { SecureRandom.base58(26) }
    amount_cents { 1000 }
    paid_on { Date.current }
    split_type { "EQUAL_ALL" }
    category { nil }
    note { nil }
  end
end
