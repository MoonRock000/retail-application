class ApprovalQueue < ApplicationRecord
  belongs_to :product
  
  enum status: {
    pending: 0,
    approved: 1,
    rejected: 2
  } 

  def approve
    product.update(status: 'active')
    self.update(status: 'approved')
  end

  def reject
    self.update(status: 'rejected')
  end

end
