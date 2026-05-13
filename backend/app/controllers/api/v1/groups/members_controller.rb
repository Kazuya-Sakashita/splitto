# frozen_string_literal: true

class Api::V1::Groups::MembersController < ApplicationController
  before_action :set_group
  before_action :authorize_member_addition!, only: %i[create]
  before_action :set_member, only: %i[leave]
  before_action :authorize_group_member!, only: %i[leave]
  before_action :authorize_self_only!,    only: %i[leave]
  before_action :authorize_not_owner!, only: %i[leave]

  def create
    user = User.find_by!(public_id: member_params[:user_id])
    existing_member = @group.members.find_by(user: user)

    if existing_member&.active?
      return render_conflict(
        reason: "member_already_exists",
        detail: "User is already a member of this group"
      )
    end

    member = @group.join_or_rejoin!(user)

    render json: { member: member_response(member) }, status: :created
  rescue ActiveRecord::RecordNotFound
    render_not_found(
      reason: "user_not_found",
      detail: "User not found"
    )
  rescue ActiveRecord::RecordNotUnique
    render_conflict(
      reason: "member_already_exists",
      detail: "User is already a member of this group"
    )
  end

  def leave
    @member.leave!
    render json: { member: member_response(@member) }, status: :ok
  end

  private

  def set_group
    @group = Group.find_by(public_id: params[:group_id])
    return if @group.present?

    render_not_found(
      reason: "group_not_found",
      detail: "Group not found"
    )
  end

  def set_member
    @member = @group.members.find_by(public_id: params[:id])
    return if @member.present?

    render_not_found(
      reason: "member_not_found",
      detail: "Member not found"
    )
  end

  def authorize_member_addition!
    current_member = @group.members.find_by(user: current_user, active: true)

    return render_forbidden(reason: "not_group_member", detail: "You are not a member of this group") unless current_member
    return if current_member.role == "OWNER"

    render_forbidden(
      reason: "insufficient_role",
      detail: "Only owner can add members"
    )
  end

  def authorize_group_member!
    # 退出の冪等性を保つため、inactive メンバーによる自身の再退出も許可する
    return if @group.members.exists?(user: current_user)

    render_forbidden(
      reason: "not_group_member",
      detail: "You are not a member of this group"
    )
  end

  def authorize_self_only!
    return if @member.user_id == current_user.id

    render_forbidden(
      reason: "cannot_leave_other_member",
      detail: "You can only leave the group as yourself"
    )
  end

  def authorize_not_owner!
    return unless @member.role == Member::ROLE_OWNER

    render_unprocessable_entity(
      reason: "owner_cannot_leave",
      detail: "Owner cannot leave the group"
    )
  end

  def member_params
    params.permit(:user_id)
  end

  def member_response(member)
    {
      id: member.public_id,
      group_id: member.group.public_id,
      user_id: member.user.public_id,
      role: member.role,
      active: member.active,
      joined_at: member.joined_at&.iso8601,
      left_at: member.left_at&.iso8601,
      created_at: member.created_at&.iso8601,
      updated_at: member.updated_at&.iso8601
    }
  end
end
