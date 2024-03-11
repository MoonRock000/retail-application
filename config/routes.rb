Rails.application.routes.draw do
  namespace :api do
    resources :products, only: [:index, :create, :update, :destroy] do
      collection do
        get 'search'
        get 'approval_queue'
        put 'approval-queue/:approval_id/approve', to: 'products#approve_from_approval_queue'
        put 'approval-queue/:approval_id/reject', to: 'products#reject_from_approval_queue'
      end
    end
  end
end
