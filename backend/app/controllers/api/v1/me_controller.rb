# frozen_string_literal: true

module Api
  module V1
    class MeController < ApplicationController
      include ClerkAuthenticatable

      def show
        render json: { id: current_user.id, external_uid: current_user.external_uid }
      end
    end
  end
end
