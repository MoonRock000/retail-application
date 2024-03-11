class Api::ProductsController < ApplicationController

  def index
    @products = Product.where(status: 'active').order(created_at: :desc)
    render json: @products
  end

  def search
    product_name = params[:productName]
    min_price = params[:minPrice]
    max_price = params[:maxPrice]
    min_posted_date = params[:minPostedDate]
    max_posted_date = params[:maxPostedDate]

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
    if @product.price > 5000
      @product.status = 'pending'
      @product.approval_queues.build(status: 'pending')
    end

    if @product.price > 10000
      render json: { errors: ['Product price cannot exceed $10,000.'] }, status: :unprocessable_entity
    elsif @product.save
      render json: @product, status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  def product_params
    params.permit(:product_name, :price)
  end

end
