Rails.application.routes.draw do
  devise_for :users

  # Main app (requires auth)
  resources :projects do
    resources :endpoints do
      member do
        patch :set_baseline
      end
    end
  end

  resources :snapshots, only: %i[index show create]
  resources :diff_reports, only: %i[show create]

  # CI/CD API
  namespace :api do
    namespace :v1 do
      resources :snapshots, only: [] do
        collection do
          post :capture
        end
      end
      resources :endpoints, only: [] do
        member do
          patch :baseline
        end
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  root "projects#index"
end
