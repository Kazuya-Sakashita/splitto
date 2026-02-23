# frozen_string_literal: true

class Api::V1::GroupsController < ApplicationController
  PER_PAGE = 20

  def index
    page = params.fetch(:page, 1).to_i
    page = 1 if page < 1
    per_page = PER_PAGE

    # 「自分が active=true で所属している group」のみを母集団として確定
    member_group_ids = current_user
      .members
      .active
      .select(:group_id)

    # total_count も同じ母集団（= 自分の active 所属グループ数）
    total_count = member_group_ids.distinct.count

    #  一覧に出す group は「自分の active 所属」だけに限定した上で、
    #  member_count は「その group の active members」を数える
    base_scope = Group
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

    groups = base_scope
      .order("groups.updated_at DESC")
      .limit(per_page)
      .offset((page - 1) * per_page)

    render json: {
      groups: groups.map { |g| group_list_json(g) },
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

  # GET /groups 用
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
