FactoryBot.define do
  factory :activity do
    opportunity
    kind { "email" }
    occurred_on { Date.current }
    body { "Sent an intro note." }
  end
end
