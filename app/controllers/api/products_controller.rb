class Api::ProductsController < ApplicationController
  before_action :set_product, only: [:update, :destroy]

  def index
    @products = Product.active.order(created_at: :desc)
    render json: @products
  end

  def search
    product_name = params[:product_name]
    min_price = params[:min_price]
    max_price = params[:max_price]
    min_posted_date = params[:min_posted_date]
    max_posted_date = params[:max_posted_date]

    query = Product.all
    query = query.where("product_name = ?", product_name) if product_name.present?
    query = query.where("price >= ?", min_price.to_f) if min_price.present?
    query = query.where("price <= ?", max_price.to_f) if max_price.present?
    query = query.where("created_at >= ?", min_posted_date.to_datetime) if min_posted_date.present?
    query = query.where("created_at <= ?", max_posted_date.to_datetime) if max_posted_date.present?

    @products = query.order(created_at: :desc)
    render json: @products
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      render json: @product, status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @product.price = product_params[:price]
    if @product.update(product_params)
      render json: @product
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
    
  end

  def destroy
    @product.push_to_approval_queue
    @product.update(status: 'inactive')
    render json: { message: 'Product deleted successfully' }
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.permit(:product_name, :price, :status)
  end

end
