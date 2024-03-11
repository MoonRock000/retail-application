FactoryBot.define do
  factory :product do
    product_name { Faker::Book.title }
    price { Faker::Number.between(from: 10, to: 100) }
    status { :active }
  end
end
