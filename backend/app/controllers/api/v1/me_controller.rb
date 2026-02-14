# frozen_string_literal: true

module Api
  module V1
    class MeController < ApplicationController
      def show
        user = current_user

        # 念のため（想定外で current_user が nil になっても 500 を避ける）
        return render_unauthorized("missing_token") if user.nil?

        render json: { user: user_json(user) }, status: :ok
      end

      private

      def user_json(user)
        {
          id: user.id,
          external_uid: user.external_uid,
          name: user.name,
          email: user.email,
          notify_email: user.notify_email,
          theme_mode: user.theme_mode,
          created_at: user.created_at&.iso8601,
          updated_at: user.updated_at&.iso8601
        }
      end
    end
  end
end
