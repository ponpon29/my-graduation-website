Rails.application.routes.draw do
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
  
  root 'static_pages#top'
  
  # 全体のレビュー一覧を先に定義
  resources :reviews, only: [:index]
  
  resources :shops, only: [:index, :show] do
    member do
      post :favorite
      delete :unfavorite
    end
    collection do
      get :favorites  
    end
    resources :reviews, only: [:new, :create, :destroy, :edit, :update]  # indexを除外
  end
  
  resources :maps, only: [:index]
  resources :users, only: %i[new create show edit update]
  resources :password_resets, only: %i[new create edit update]

  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'
  
  get "oauth/:provider" => "oauths#oauth", as: :auth_at_provider
  get "oauth/:provider/callback" => "oauths#callback", as: :oauth_callback
  get "oauth/failure" => "oauths#failure", as: :oauth_failure
  
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end