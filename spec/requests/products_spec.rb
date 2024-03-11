require 'rails_helper'
require 'factory_bot_rails'

RSpec.describe 'Products API', type: :request do
  describe 'GET /api/products' do
    it 'returns a successful response' do
      get '/api/products'
      expect(response).to have_http_status(:success)
    end

    it 'returns JSON format' do
      get '/api/products'
      expect(response.content_type).to eq('application/json; charset=utf-8')
    end

    it 'returns active products in descending order of creation' do
      active_product1 = create(:product, status: :active, created_at: 2.days.ago)
      active_product2 = create(:product, status: :active, created_at: 1.day.ago)
      inactive_product = create(:product, status: :inactive, created_at: 3.days.ago)

      get '/api/products'

      expect(response).to have_http_status(:success)

      products = JSON.parse(response.body)
      expect(products.length).to eq(2)
      expect(products.first['id']).to eq(active_product2.id)
      expect(products.second['id']).to eq(active_product1.id)
    end
  end

  describe 'GET /api/products/search' do
    it 'returns a successful response with valid parameters' do
      product1 = create(:product, product_name: 'Test Product 1', price: 100, created_at: 1.day.ago)
      product2 = create(:product, product_name: 'Test Product 2', price: 200, created_at: 2.days.ago)

      sleep 3
      get '/api/products/search', params: { product_name: 'Test Product 1', min_price: 50, max_price: 150, min_posted_date: 3.days.ago, max_posted_date: 1.day.ago }
      expect(response).to have_http_status(:success)

      products = JSON.parse(response.body)
      expect(products.length).to eq(1)
      expect(products.first['id']).to eq(product1.id)
    end

    it 'returns all products when no search parameters are provided' do
      product1 = create(:product, product_name: 'Test Product 1', price: 100, created_at: 1.day.ago)
      product2 = create(:product, product_name: 'Test Product 2', price: 200, created_at: 2.days.ago)

      get '/api/products/search'
      expect(response).to have_http_status(:success)

      products = JSON.parse(response.body)
      expect(products.length).to eq(2)
    end

    it 'returns an empty array when no matching products are found' do
      get '/api/products/search', params: { product_name: 'Non-existent Product' }
      expect(response).to have_http_status(:success)

      products = JSON.parse(response.body)
      expect(products).to be_empty
    end
  end

  describe 'POST /api/products' do
    it 'creates a new product with valid parameters' do
      post '/api/products', params: { product_name: 'Test Product', price: 500, status: 'active' }
      expect(response).to have_http_status(:created)

      product = JSON.parse(response.body)
      expect(product['product_name']).to eq('Test Product')
    end

    it 'fails to create a product with price exceeding $10,000' do
      post '/api/products', params: { product_name: 'Expensive Product', price: 12000, status: 'active' }

      errors = JSON.parse(response.body)
      expect(errors['errors']).to include('Price must be less than or equal to 10000')
    end
  end

  describe 'PUT /api/products/:id' do
    let(:product) { create(:product, price: 5000) }

    it 'updates the product with valid parameters' do
      put "/api/products/#{product.id}", params: { product_name: 'Updated Product', price: 6000, status: 'active' }
      expect(response).to have_http_status(:success)

      updated_product = JSON.parse(response.body)
      expect(updated_product['product_name']).to eq('Updated Product')
      expect(updated_product['price']).to eq(6000)
    end

    it 'fails to update product with price exceeding $10,000' do
      put "/api/products/#{product.id}", params: { price: 12000 }

      errors = JSON.parse(response.body)
      expect(errors['errors']).to include('Price must be less than or equal to 10000')
    end

    it 'creates an approval queue when price increases over threshold' do
      put "/api/products/#{product.id}", params: { price: 9000 }
      expect(response).to have_http_status(:success)

      updated_product = Product.find(product.id)
      expect(updated_product.approval_queues.last.status).to eq('pending')
    end
  end

  describe 'DELETE /api/products/:id' do
    let(:product) { create(:product, status: 'active') }

    it 'deletes the product and creates an approval queue' do
      delete "/api/products/#{product.id}"
      expect(ApprovalQueue.exists?(product_id: product.id, status: 'pending')).to be_truthy
      expect(product.reload.status).to eq('inactive')
      message = JSON.parse(response.body)
      expect(message['message']).to eq('Product deleted successfully')
      expect(response).to have_http_status(:success)
    end
  end

end
