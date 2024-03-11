require 'rails_helper'
require 'factory_bot_rails'


RSpec.describe Api::ProductsController, type: :controller do
  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'returns JSON format' do
      get :index
      expect(response.content_type).to eq('application/json; charset=utf-8')
    end

    it 'returns active products in descending order of creation' do
      active_product1 = create(:product, status: :active, created_at: 2.days.ago)
      active_product2 = create(:product, status: :active, created_at: 1.day.ago)
      inactive_product = create(:product, status: :inactive, created_at: 3.days.ago)

      get :index

      expect(response).to have_http_status(:success)

      products = JSON.parse(response.body)
      puts products
      expect(products.length).to eq(2)
      expect(products.first['id']).to eq(active_product2.id)
      expect(products.second['id']).to eq(active_product1.id)
    end
  end

  describe 'GET #search' do
    it 'returns a successful response with valid parameters' do
      product1 = create(:product, product_name: 'Test Product 1', price: 100, created_at: 1.day.ago)
      product2 = create(:product, product_name: 'Test Product 2', price: 200, created_at: 2.days.ago)
      sleep 3
      get :search, params: { productName: 'Test Product 1', minPrice: 50, maxPrice: 150, minPostedDate: 3.days.ago, maxPostedDate: 1.day.ago }
      expect(response).to have_http_status(:success)
      products = JSON.parse(response.body)
      expect(products.length).to eq(1)
      expect(products.first['id']).to eq(product1.id)
    end

    it 'returns all products when no search parameters are provided' do
      product1 = create(:product, product_name: 'Test Product 1', price: 100, created_at: 1.day.ago)
      product2 = create(:product, product_name: 'Test Product 2', price: 200, created_at: 2.days.ago)

      get :search
      expect(response).to have_http_status(:success)

      products = JSON.parse(response.body)
      expect(products.length).to eq(2)
    end

    it 'returns an empty array when no matching products are found' do
      get :search, params: { productName: 'Non-existent Product' }
      expect(response).to have_http_status(:success)

      products = JSON.parse(response.body)
      expect(products).to be_empty
    end
  end

  describe 'POST #create' do
    it 'creates a new product with valid parameters' do
      post :create, params: { product_name: 'Test Product', price: 500, status: 'active' }
      expect(response).to have_http_status(:created)

      product = JSON.parse(response.body)
      expect(product['product_name']).to eq('Test Product')
    end

    it 'fails to create a product with price exceeding $10,000' do
      post :create, params: { product_name: 'Expensive Product', price: 12000, status: 'active' }
      expect(response).to have_http_status(:unprocessable_entity)

      errors = JSON.parse(response.body)
      expect(errors['errors']).to include('Product price cannot exceed $10,000.')
    end

  end

  describe 'PUT #update' do
    let(:product) { create(:product, price: 5000) }

    it 'updates the product with valid parameters' do
      put :update, params: { id: product.id, product_name: 'Updated Product', price: 6000, status: 'active' }
      expect(response).to have_http_status(:success)

      updated_product = JSON.parse(response.body)
      expect(updated_product['product_name']).to eq('Updated Product')
      expect(updated_product['price']).to eq(6000)
    end

    it 'fails to update product with price exceeding $10,000' do
      put :update, params: { id: product.id, price: 12000 }
      expect(response).to have_http_status(:unprocessable_entity)

      errors = JSON.parse(response.body)
      expect(errors['errors']).to include('Product price cannot exceed $10,000.')
    end

    it 'creates an approval queue when price increases over threshold' do
      put :update, params: { id: product.id, price: 9000 }
      expect(response).to have_http_status(:success)

      updated_product = Product.find(product.id)
      expect(updated_product.approval_queues.last.status).to eq('pending')
    end

    it 'does not create an approval queue if price does not increase over threshold' do
      put :update, params: { id: product.id, price: 5500 }
      expect(response).to have_http_status(:success)

      updated_product = Product.find(product.id)
      expect(updated_product.approval_queues).to be_empty
    end

  end

  describe 'DELETE #destroy' do
    let(:product) { create(:product, status: 'active') }

    it 'deletes the product and creates an approval queue' do
      delete :destroy, params: { id: product.id }
      expect(ApprovalQueue.exists?(product_id: product.id, status: 'pending')).to be_truthy
      expect(product.reload.status).to eq('inactive')
      message = JSON.parse(response.body)
      expect(message['message']).to eq('Product deleted successfully')
    end

  end

  describe 'GET #approval_queue' do
    let!(:approved_product) { create(:product) }
    let!(:pending_product_1) { create(:product) }
    let!(:pending_product_2) { create(:product) }

    before do
      create(:approval_queue, product: pending_product_1, status: 'pending', created_at: 1.day.ago)
      create(:approval_queue, product: pending_product_2, status: 'pending', created_at: 2.days.ago)
    end

    it 'returns products in the approval queue with status "pending"' do
      get :approval_queue
      expect(response).to have_http_status(:success)

      approval_queue_products = JSON.parse(response.body)
      expect(approval_queue_products.count).to eq(2)

      expect(approval_queue_products.first['id']).to eq(pending_product_2.id)
      expect(approval_queue_products.last['id']).to eq(pending_product_1.id)
    end

    it 'orders products in the approval queue by request date (earliest first)' do
      get :approval_queue
      expect(response).to have_http_status(:success)

      approval_queue_products = JSON.parse(response.body)
      expect(approval_queue_products.count).to eq(2)

      expect(approval_queue_products.first['id']).to eq(pending_product_2.id)
      expect(approval_queue_products.last['id']).to eq(pending_product_1.id)
    end

    it 'returns an empty array if there are no products in the approval queue' do
      ApprovalQueue.destroy_all
      get :approval_queue
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
