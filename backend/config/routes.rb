# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "me", to: "me#show"
      get "me/shared_group_users", to: "me/shared_group_users#index"

      resources :groups, only: %i[index create show] do
        resources :members, only: [:create], module: :groups do
          member do
            post :leave
          end
        end
        resource :invite_token, only: [:update], module: :groups
      end

      resources :invites, param: :invite_token, only: [:show]

      post "invites/:invite_token/membership", to: "invites/memberships#create"
    end
  end
end
