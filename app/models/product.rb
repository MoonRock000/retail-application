class Product < ApplicationRecord
  has_many :approval_queues, dependent: :destroy
  validates :price, numericality: { less_than_or_equal_to: 10000 }
  before_save :check_price_and_create_approval_queue
  before_update :check_and_build_pending_approval_queue
  
  enum status: {
    inactive: 0,
    active: 1,
  } 

  
  
  def check_and_build_pending_approval_queue
    return unless self.price_changed?
    if price_increase_over_threshold?(self.price_change[0], self.price_change[1])
      approval_queues.find_or_initialize_by(status: 'pending')
    end
  end
  
  def push_to_approval_queue
    approval_queues.find_or_create_by(status: 'pending')
  end
  
  private


  def price_increase_over_threshold?(old_price, new_price)
    percentage_increase = ((new_price - old_price).to_f / old_price) * 100
    percentage_increase > 50
  end

  def check_price_and_create_approval_queue
    if price > 5000
      approval_queues.find_or_initialize_by(status: 'pending')
    end
  end

end
