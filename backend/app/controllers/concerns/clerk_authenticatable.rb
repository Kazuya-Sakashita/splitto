# frozen_string_literal: true

module ClerkAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_with_clerk!
    attr_reader :current_user, :current_clerk_payload
  end

  private

  def authenticate_with_clerk!
    token = bearer_token
    return render_unauthorized("missing_token") unless token

    payload = Clerk::JwtVerifier.verify!(token)
    @current_clerk_payload = payload

    sub = payload.fetch("sub")
    @current_user = User.find_or_create_by!(external_uid: sub)

    Rails.logger.info("[ClerkAuthenticatable] ok user_id=#{@current_user.id} external_uid=#{@current_user.external_uid}")
  rescue Clerk::JwtVerifier::VerificationError => e
    Rails.logger.warn("[ClerkAuthenticatable] jwt verification failed: #{e.class}: #{e.message}")
    render_unauthorized("invalid_token")
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    Rails.logger.warn("[ClerkAuthenticatable] user upsert failed: #{e.class}: #{e.message}")
    render_unauthorized("user_sync_failed")
  end

  def bearer_token
    value = request.headers["Authorization"].to_s
    scheme, token = value.split(" ", 2)
    return nil unless scheme&.casecmp("Bearer")&.zero?
    token.presence
  end

  def render_unauthorized(reason, extra = {})
    render json: { error: "Unauthorized", reason:, **extra }, status: :unauthorized
  end
end
