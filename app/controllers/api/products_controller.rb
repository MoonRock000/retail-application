class Api::ProductsController < ApplicationController
  before_action :set_product, only: [:update, :destroy]

  def index
    @products = Product.active.order(created_at: :desc)
    render json: @products
  end

  def search
    query = Product.all
    query = query.where("product_name = ?", params[:product_name]) if params[:product_name].present?
    query = query.where("price >= ?", params[:min_price].to_f) if params[:min_price].present?
    query = query.where("price <= ?", params[:max_price].to_f) if params[:max_price].present?
    query = query.where("created_at >= ?", params[:min_posted_date].to_datetime) if params[:min_posted_date].present?
    query = query.where("created_at <= ?", params[:max_posted_date].to_datetime) if params[:max_posted_date].present?

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
