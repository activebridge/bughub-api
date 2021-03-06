# frozen_string_literal: true

FactoryBot.define do
  factory :subscription do
    association :plan
    association :project

    trait :expired do
      expires_at { 1.month.ago }
      status { :expired }
      events { 0 }

      after(:build) { |subscription| subscription.class.skip_callback(:create) }
    end
  end
end
