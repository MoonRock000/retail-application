Rails.application.routes.draw do
  get 'approval_queues/approve'
  get 'approval_queues/reject'
  namespace :api do
    resources :products, except: [:show, :new, :edit] do
      collection do
        get 'search'
        resources :approval_queues, only: [:index] do
          member do
            put 'approve'
            put 'reject'
          end
        end
      end
    end
  end
end
