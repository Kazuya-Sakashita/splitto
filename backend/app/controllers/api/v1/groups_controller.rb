class Api::V1::GroupsController < ApplicationController
  include ClerkAuthenticatable

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

    render json: { group: group }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def group_params
    params.require(:group).permit(:name, :currency)
  end
end
