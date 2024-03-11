class Api::ProductsController < ApplicationController
  before_action :set_product, only: [:update, :destroy]

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
      @product.approval_queues.find_or_initialize_by(status: 'pending')
    end

    if @product.price > 10000
      render json: { errors: ['Product price cannot exceed $10,000.'] }, status: :unprocessable_entity
    elsif @product.save
      render json: @product, status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    new_price = params[:price].to_i
    if new_price > 10000
      render json: { errors: ['Product price cannot exceed $10,000.'] }, status: :unprocessable_entity
      return
    elsif @product.price_increase_over_threshold?(new_price)
      @product.approval_queues.find_or_initialize_by(status: 'pending')
    end

    if @product.update(product_params)
      render json: @product
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
    
  end

  def destroy
    push_to_approval_queue
    @product.update(status: 'inactive')
    render json: { message: 'Product deleted successfully' }
  end

  def approval_queue
    approval_queue_products = Product.joins(:approval_queues)
                                     .where(approval_queues: { status: 'pending' })
                                     .order('approval_queues.created_at ASC')
    render json: approval_queue_products
  end

  def approve_from_approval_queue
    approval_queue_product = ApprovalQueue.find(params[:approval_id])

    if approval_queue_product.approve
      render json: { message: 'Product approved successfully' }
    else
      render json: { errors: approval_queue_product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def reject_from_approval_queue
    approval_queue_product = ApprovalQueue.find(params[:approval_id])

    if approval_queue_product.reject
      render json: { message: 'Product rejected successfully' }
    else
      render json: { errors: approval_queue_product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.permit(:product_name, :price, :status)
  end

  def push_to_approval_queue
    @product.approval_queues.find_or_create_by(status: 'pending')
  end

end
