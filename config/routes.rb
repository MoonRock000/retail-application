Rails.application.routes.draw do
  namespace :api do
    resources :products, only: [:index, :create, :update, :destroy] do
      collection do
        get 'search'
      end
    end
  end
end
