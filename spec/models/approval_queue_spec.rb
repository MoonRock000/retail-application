require 'rails_helper'
require 'shoulda/matchers'


RSpec.describe ApprovalQueue, type: :model do
  include Shoulda::Matchers::ActiveModel
  include Shoulda::Matchers::ActiveRecord

  describe 'associations' do
    it { should belong_to(:product) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, approved: 1, rejected: 2) }
  end

  describe 'methods' do
    let(:product) { create(:product) } # Assuming you have a factory for Product
    let(:approval_queue) { create(:approval_queue, product: product) } # Assuming you have a factory for ApprovalQueue

    it 'approves the approval queue and updates the product status to active' do
      approval_queue.approve

      approval_queue.status.should eq('approved')
      product.reload.status.should eq('active')
    end

    it 'rejects the approval queue' do
      approval_queue.reject

      approval_queue.status.should eq('rejected')
    end
  end
end
