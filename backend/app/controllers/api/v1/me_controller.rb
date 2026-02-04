# frozen_string_literal: true

module Api
  module V1
    class MeController < ApplicationController
      include ClerkAuthenticatable

      def show
        render json: { user: current_user.as_json(only: %i[id external_uid name email notify_email theme_mode created_at updated_at]) }
      end
    end
  end
end
