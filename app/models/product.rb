class Product < ApplicationRecord
  has_many :approval_queues
  enum status: {
    pending: 0,
    active: 1,
  } 

  def price_increase_over_threshold?(new_price)
      percentage_increase = ((new_price - price).to_f / price) * 100
    percentage_increase > 50
  end

end
