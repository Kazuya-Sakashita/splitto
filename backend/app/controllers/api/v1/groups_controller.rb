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
        joined_at: Time.current
      )
    end

    render json: { group: group_json(group) }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
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
      created_at: group.created_at.iso8601,
      updated_at: group.updated_at.iso8601
    }
  end
end
