class Product < ApplicationRecord
  enum status: {
    pending: 0,
    active: 1,
  } 
end
