# frozen_string_literal: true

class Api::V1::GroupsController < ApplicationController
  def create
    group = nil

    ActiveRecord::Base.transaction do
      group = Group.create!(group_params)

      Member.create!(
        group: group,
        user: current_user,
        role: "OWNER",
        active: true,
        joined_at: Time.current,
        left_at: nil
      )
    end

    render json: { group: group_json(group) }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_validation_error(e.record)
  rescue StandardError => e
    Rails.logger.error("[GroupsController#create] #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if e.backtrace.present?
    render_internal_server_error
  end

  private

  def group_params
    params.require(:group).permit(:name, :currency)
  end

  def group_json(group)
    {
      public_id: group.public_id,
      name: group.name,
      currency: group.currency,
      invite_token: group.invite_token,
      created_at: group.created_at&.iso8601,
      updated_at: group.updated_at&.iso8601
    }
  end
end
