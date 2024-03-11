class Product < ApplicationRecord
  has_many :approval_queues
  enum status: {
    pending: 0,
    active: 1,
  } 
end
