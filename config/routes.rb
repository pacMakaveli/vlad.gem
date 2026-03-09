Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Root path
  root "conversations#index"

  # Conversations
  resources :conversations do
    # Import batches
    resources :import_batches, only: [:index, :show, :new, :create, :destroy]

    # Analytics views
    get "analytics/timeline", to: "analytics#timeline", as: :timeline
    get "analytics/pulse", to: "analytics#pulse", as: :pulse
    get "analytics/shift", to: "analytics#shift", as: :shift
    get "analytics/chapters", to: "analytics#chapters", as: :chapters
    get "analytics/new_since_last", to: "analytics#new_since_last", as: :new_since_last
    get "analytics/response_drift", to: "analytics#response_drift", as: :response_drift
    get "analytics/daily_rhythm", to: "analytics#daily_rhythm", as: :daily_rhythm
    get "analytics/daily_breakdown", to: "analytics#daily_breakdown", as: :daily_breakdown
    get "analytics/chart_data", to: "analytics#chart_data", as: :chart_data
  end

  # Messages (for audio transcript attachment)
  resources :messages, only: [:show] do
    resources :audio_transcripts, only: [:show, :new, :create, :destroy] do
      member do
        post :retry_transcription
      end
    end
  end

  # Sidekiq web UI (optional, requires authentication in production)
  # require "sidekiq/web"
  # mount Sidekiq::Web => "/sidekiq"
end
