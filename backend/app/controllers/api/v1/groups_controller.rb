# frozen_string_literal: true

class Api::V1::GroupsController < ApplicationController
  def index
    member_group_ids = Member.where(user_id: current_user.id, active: true).select(:group_id)

    groups = Group
      .where(id: member_group_ids)
      .left_joins(:members)
      .where(members: { active: true })
      .group(
        "groups.id, groups.public_id, groups.name, groups.currency, groups.updated_at"
      )
      .select(
        "groups.public_id, groups.name, groups.currency, groups.updated_at, COUNT(members.id) AS member_count"
      )
      .order("groups.updated_at DESC")

    render json: {
      groups: groups.map { |g| group_list_json(g) },
      meta: {
        page: 1,
        per_page: groups.size,
        total_count: groups.size,
        total_pages: 1
      }
    }, status: :ok
  end



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

  # GET /groups 用（member_count 追加）

  def group_list_json(group)
    {
      public_id: group.public_id,
      name: group.name,
      currency: group.currency,
      updated_at: group.updated_at&.iso8601,
      member_count: group.read_attribute(:member_count).to_i
    }
  end
end
