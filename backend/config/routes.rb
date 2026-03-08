# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "me", to: "me#show"

      resources :groups, only: %i[index create]
      resources :invites, param: :invite_token, only: [:show]

      post "invites/:invite_token/membership", to: "invites/memberships#create"
    end
  end
end
