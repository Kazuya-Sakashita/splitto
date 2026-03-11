# frozen_string_literal: true

class Api::V1::Groups::MembersController < ApplicationController
  before_action :set_group
  before_action :authorize_member_create!

  def create
    member = @group.add_member!(user_public_id: member_params[:user_id])

    render json: { member: member_response(member) }, status: :created
  rescue ActiveRecord::RecordNotFound
    render_not_found(
      reason: "user_not_found",
      detail: "User not found"
    )
  rescue Group::MemberAlreadyExistsError
    render_conflict(
      reason: "member_already_exists",
      detail: "User is already a member of this group"
    )
  end

  private

  def set_group
    @group = Group.find_by!(public_id: params[:group_id])
  rescue ActiveRecord::RecordNotFound
    render_not_found(
      reason: "group_not_found",
      detail: "Group not found"
    )
  end

  def authorize_member_create!
    current_member = @group.members.find_by(user: current_user, active: true)

    return render_forbidden(reason: "not_group_member", detail: "You are not a member of this group") unless current_member
    return if current_member.role == "OWNER"

    render_forbidden(
      reason: "insufficient_role",
      detail: "Only owner can add members"
    )
  end

  def member_params
    params.permit(:user_id)
  end

  def member_response(member)
    {
      id: member.id,
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
