class Api::ProductsController < ApplicationController

  def index
    @products = Product.where(status: 'active').order(created_at: :desc)
    render json: @products
  end
end
