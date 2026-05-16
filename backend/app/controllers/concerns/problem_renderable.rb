# frozen_string_literal: true

module ProblemRenderable
  extend ActiveSupport::Concern

  PROBLEM_JSON = "application/problem+json"

  private

  # RFC9457 (Problem Details)
  #
  # NOTE:
  # - OpenAPI で detail が required の想定なので常に string を返す
  # - status は integer を想定（Symbol を渡さない）
  def render_problem(title:, status:, reason:, errors: nil, detail: nil, type: "about:blank", instance: nil, **ext)
    payload = {
      type: type,
      title: title,
      status: status,
      reason: reason,
      detail: detail.to_s
    }

    payload[:instance] = instance if instance.present?
    payload[:errors] = errors if errors.present?
    payload.merge!(ext) if ext.present?

    render json: payload, status: status, content_type: PROBLEM_JSON
  end

  # 404 の detail を指定して返す（共通化）
  #
  # NOTE:
  # - detail は OpenAPI 上 required 前提のため、呼び出し側で渡す運用を推奨
  def render_not_found(reason: "not_found", detail: nil, type: "about:blank", instance: nil, **ext)
    render_problem(
      title: "Not Found",
      status: 404,
      reason: reason,
      detail: detail,
      type: type,
      instance: instance,
      **ext
    )
  end

  # 401 の detail を reason から解決して埋める（spec の期待に合わせる）
  def render_unauthorized(reason, detail: nil, type: "about:blank", instance: nil, **ext)
    resolved_detail =
      detail.presence ||
      case reason
      when "missing_token"
        "Authorization header is missing or invalid"
      when "invalid_token"
        "Token verification failed"
      when "user_sync_failed"
        "User synchronization failed"
      else
        "Authentication failed"
      end

    render_problem(
      title: "Unauthorized",
      status: 401,
      reason: reason,
      detail: resolved_detail,
      type: type,
      instance: instance,
      **ext
    )
  end

  def render_validation_error(record, reason: "validation_error", detail: nil)
    render_problem(
      title: "Unprocessable Entity",
      status: 422,
      reason: reason,
      detail: detail,
      errors: record.errors.messages
    )
  end

  def render_unprocessable_entity(reason:, detail: nil, type: "about:blank", instance: nil, **ext)
    render_problem(
      title: "Unprocessable Entity",
      status: 422,
      reason: reason,
      detail: detail,
      type: type,
      instance: instance,
      **ext
    )
  end

  def render_internal_server_error(reason: "internal_server_error", detail: nil)
    render_problem(
      title: "Internal Server Error",
      status: 500,
      reason: reason,
      detail: detail
    )
  end

  def render_forbidden(reason:, detail: nil, type: "about:blank", instance: nil, **ext)
    render_problem(
      title: "Forbidden",
      status: 403,
      reason: reason,
      detail: detail,
      type: type,
      instance: instance,
      **ext
    )
  end

  def render_conflict(reason:, detail: nil, type: "about:blank", instance: nil, **ext)
    render_problem(
      title: "Conflict",
      status: 409,
      reason: reason,
      detail: detail,
      type: type,
      instance: instance,
      **ext
    )
  end
end
