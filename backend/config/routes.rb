# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "me", to: "me#show"
      post "groups", to: "groups#create"
    end
  end
end
