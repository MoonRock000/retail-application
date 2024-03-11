FactoryBot.define do
  factory :product do
    product_name { 'Book1' }
    price { 25 }
    status { :active }
  end
end
