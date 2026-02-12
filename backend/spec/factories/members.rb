FactoryBot.define do
  factory :member do
    association :group
    association :user

    role { "MEMBER" }
    active { true }
    joined_at { Time.current }
  end
end
