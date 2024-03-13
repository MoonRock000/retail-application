require 'rails_helper'
require 'factory_bot_rails'

RSpec.describe 'ApprovalQueues API', type: :request do
  describe 'GET /api/products/approval_queues' do
    let!(:approved_product) { create(:product) }
    let!(:pending_product_1) { create(:product) }
    let!(:pending_product_2) { create(:product) }

    before do
      create(:approval_queue, product: pending_product_1, status: 'pending', created_at: 1.day.ago)
      create(:approval_queue, product: pending_product_2, status: 'pending', created_at: 2.days.ago)
    end

    it 'returns products in the approval queue with status "pending"' do
      get '/api/products/approval_queues'
      expect(response).to have_http_status(:success)

      approval_queue_products = JSON.parse(response.body)
      expect(approval_queue_products.count).to eq(2)

      expect(approval_queue_products.first['id']).to eq(pending_product_2.id)
      expect(approval_queue_products.last['id']).to eq(pending_product_1.id)
    end

    it 'orders products in the approval queue by request date (earliest first)' do
      get '/api/products/approval_queues'
      expect(response).to have_http_status(:success)

      approval_queue_products = JSON.parse(response.body)
      expect(approval_queue_products.count).to eq(2)

      expect(approval_queue_products.first['id']).to eq(pending_product_2.id)
      expect(approval_queue_products.last['id']).to eq(pending_product_1.id)
    end

    it 'returns an empty array if there are no products in the approval queue' do
      ApprovalQueue.destroy_all
      get '/api/products/approval_queues'
      expect(response).to have_http_status(:success)

      approval_queue_products = JSON.parse(response.body)
      expect(approval_queue_products).to be_empty
    end
  end

  describe 'PUT /api/products/approval_queues/:id/approve' do
    let(:product) { create(:product) }
    let(:approval_queue) { create(:approval_queue, product: product, status: 'pending') }

    it 'approves the product and updates the approval_queue status to "approved"' do
      expect(approval_queue.status).to eq('pending')

      put "/api/products/approval_queues/#{approval_queue.id}/approve"

      expect(approval_queue.reload.status).to eq('approved')
      expect(response).to be_successful
    end

    it 'returns true on successful approval' do
      put "/api/products/approval_queues/#{approval_queue.id}/approve"

      expect(response).to be_successful
      expect(approval_queue.reload.status).to eq('approved')
    end
  end

  describe 'PUT /api/products/approval_queues/:id/reject' do 
    let(:product) { create(:product) }
    let(:approval_queue) { create(:approval_queue,product: product, status: 'pending') }

    it 'rejects the approval_queue and updates the status to "rejected"' do
      expect(approval_queue.status).to eq('pending')

      put "/api/products/approval_queues/#{approval_queue.id}/reject"

      expect(approval_queue.reload.status).to eq('rejected')
      expect(response).to be_successful
    end

    it 'returns true on successful rejection' do
      put "/api/products/approval_queues/#{approval_queue.id}/reject"

      expect(response).to be_successful
      expect(approval_queue.reload.status).to eq('rejected')
    end
  end
end
