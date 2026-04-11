# frozen_string_literal: true

class Api::V1::GroupsController < ApplicationController
  PER_PAGE = 20

  def index
    page = normalized_page
    per_page = PER_PAGE

    member_group_ids = current_user
      .members
      .active
      .select(:group_id)

    total_count = member_group_ids.distinct.count

    groups = Group
      .where(id: member_group_ids)
      .joins(:members)
      .merge(Member.active)
      .group("groups.id")
      .select(
        "groups.public_id,
         groups.name,
         groups.currency,
         groups.updated_at,
         COUNT(members.id) AS member_count"
      )
      .order("groups.updated_at DESC")
      .limit(per_page)
      .offset((page - 1) * per_page)

    render json: {
      groups: groups.map { |group| group_list_json(group) },
      meta: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
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

  def show
    group = find_group_by_public_id
    return render_not_found(detail: "Group not found", reason: "not_found") if group.nil?

    return render_forbidden(detail: "forbidden", reason: "forbidden") unless active_membership?(group)

    render json: {
      group: group_detail_json(group),
      members: active_members_json(group)
    }, status: :ok
  end

  private

  def normalized_page
    page = params.fetch(:page, 1).to_i
    page < 1 ? 1 : page
  end

  def find_group_by_public_id
    Group.find_by(public_id: params[:id])
  end

  def active_membership?(group)
    group.members.exists?(user: current_user, active: true)
  end

  def active_members(group)
    group.members.where(active: true).includes(:user)
  end

  def active_members_json(group)
    active_members(group).map do |member|
      {
        user_id: member.user.public_id,
        role: member.role
      }
    end
  end

  def group_detail_json(group)
    {
      public_id: group.public_id,
      name: group.name,
      currency: group.currency,
      created_at: group.created_at,
      updated_at: group.updated_at
    }
  end

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
