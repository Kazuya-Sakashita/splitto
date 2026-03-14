FactoryBot.define do
  factory :member do
    association :group
    association :user

    public_id { SecureRandom.base58(26) }
    role { "MEMBER" }
    active { true }
    joined_at { Time.current }
  end
end
