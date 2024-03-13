class Api::ApprovalQueuesController < ApplicationController
  before_action :set_approval_queue, except: [:index]

  def index
    approval_queue_products = Product.joins(:approval_queues)
                                     .where(approval_queues: { status: 'pending' })
                                     .order('approval_queues.created_at ASC')
    render json: approval_queue_products
  end

  def approve
    if @approval_queue_product.approve
      render json: { message: 'Product approved successfully' }
    else
      render json: { errors: @approval_queue_product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def reject
    
    if @approval_queue_product.reject
      render json: { message: 'Product rejected successfully' }
    else
      render json: { errors: @approval_queue_product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_approval_queue
    @approval_queue_product = ApprovalQueue.find(params[:id])
  end
end
