class Product < ApplicationRecord
  has_many :approval_queues, dependent: :destroy
  validates :price, numericality: { less_than_or_equal_to: 10000 }
  
  enum status: {
    inactive: 0,
    active: 1,
  } 

  def price_increase_over_threshold?(new_price)
      percentage_increase = ((new_price - price).to_f / price) * 100
    percentage_increase > 50
  end

end
