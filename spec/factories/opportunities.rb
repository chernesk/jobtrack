FactoryBot.define do
  factory :opportunity do
    sequence(:company) { |n| "Acme Logistics #{n}" }
    role { "Senior Rails Engineer" }
    kind { "full_time" }
    source { "network" }
    status { "not_contacted" }
    pay_unit { "yearly" }

    trait :with_pay do
      pay_min { 150_000 }
      pay_max { 180_000 }
    end
  end
end
