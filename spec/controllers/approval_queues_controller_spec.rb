require 'rails_helper'
require 'factory_bot_rails'

RSpec.describe Api::ApprovalQueuesController, type: :controller do
  describe 'GET #approval_queue' do
    let!(:approved_product) { create(:product) }
    let!(:pending_product_1) { create(:product) }
    let!(:pending_product_2) { create(:product) }
  
    before do
      create(:approval_queue, product: pending_product_1, status: 'pending', created_at: 1.day.ago)
      create(:approval_queue, product: pending_product_2, status: 'pending', created_at: 2.days.ago)
    end
  
    it 'returns products in the approval queue with status "pending"' do
      get :index
      expect(response).to have_http_status(:success)
  
      approval_queue_products = JSON.parse(response.body)
      expect(approval_queue_products.count).to eq(2)
  
      expect(approval_queue_products.first['id']).to eq(pending_product_2.id)
      expect(approval_queue_products.last['id']).to eq(pending_product_1.id)
    end
  
    it 'orders products in the approval queue by request date (earliest first)' do
      get :index
      expect(response).to have_http_status(:success)
  
      approval_queue_products = JSON.parse(response.body)
      expect(approval_queue_products.count).to eq(2)
  
      expect(approval_queue_products.first['id']).to eq(pending_product_2.id)
      expect(approval_queue_products.last['id']).to eq(pending_product_1.id)
    end
  
    it 'returns an empty array if there are no products in the approval queue' do
      ApprovalQueue.destroy_all
      get :index
      expect(response).to have_http_status(:success)
  
      approval_queue_products = JSON.parse(response.body)
      expect(approval_queue_products).to be_empty
    end
  
  end
  
  describe '#approve' do
    let(:product) { create(:product) }
    let(:approval_queue) { create(:approval_queue, product: product, status: 'pending') }
  
    it 'approves the product and updates the approval_queue status to "approved"' do
      expect(approval_queue.status).to eq('pending')
  
      approval_queue.approve
  
      expect(approval_queue.reload.status).to eq('approved')
    end
  
    it 'returns true on successful approval' do
      expect(approval_queue.approve).to be_truthy
    end
  
  end
  
  describe '#reject' do 
    let(:product) { create(:product) }
    let(:approval_queue) { create(:approval_queue,product: product, status: 'pending') }
  
    it 'rejects the approval_queue and updates the status to "rejected"' do
      expect(approval_queue.status).to eq('pending')
  
      approval_queue.reject
  
      expect(approval_queue.reload.status).to eq('rejected')
    end
  
    it 'returns true on successful rejection' do
      expect(approval_queue.reject).to be_truthy
    end
  
  end
end
