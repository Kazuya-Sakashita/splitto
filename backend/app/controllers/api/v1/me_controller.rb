# frozen_string_literal: true

class Api::V1::MeController < ApplicationController
  def show
    user = current_user

    render json: { user: user_json(user) }, status: :ok
  end

  private

  def user_json(user)
    {
      id: user.id,
      public_id: user.public_id,
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
