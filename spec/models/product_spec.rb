require 'rails_helper'
require 'shoulda/matchers'

RSpec.describe Product, type: :model do
  include Shoulda::Matchers::ActiveModel
  include Shoulda::Matchers::ActiveRecord
  
  describe 'validations' do
    it { should validate_numericality_of(:price).is_less_than_or_equal_to(10000) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(inactive: 0, active: 1) }
  end

  describe 'methods' do
    describe '#check_and_build_pending_approval_queue' do
      it 'builds a pending approval_queue if the price has increased over 50%' do
        product = create(:product, price: 500)
        product.price = 800
        product.approval_queues.should be_empty
        product.check_and_build_pending_approval_queue
        product.approval_queues.length.should eq(1)
      end
      
      it 'does not build a pending approval_queue if the price has not increased over 50%' do
        product = create(:product, price: 500)
        product.price = 600
        product.approval_queues.should be_empty
        product.check_and_build_pending_approval_queue
        product.approval_queues.should be_empty
      end
      
      it 'does not build a pending approval_queue if the price has not changed' do
        product = create(:product, price: 500)
        product.approval_queues.should be_empty
        product.check_and_build_pending_approval_queue
        product.approval_queues.should be_empty
      end
      
      describe '#push_to_approval_queue' do
        it 'creates a pending approval_queue' do
          product = create(:product, price: 3000)
          product.approval_queues.should be_empty
          product.push_to_approval_queue
          product.approval_queues.length.should eq(1)
        end
      
        it 'does not create a pending approval_queue if the price is not over 5000' do
          product = create(:product, price: 4000)
          product.approval_queues.should be_empty
        end
      end
    end
  end
end
