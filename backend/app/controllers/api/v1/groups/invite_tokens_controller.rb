# frozen_string_literal: true

module Api
  module V1
    module Groups
      class InviteTokensController < ApplicationController
        before_action :set_group
        before_action :authorize_owner!

        def update
          @group.regenerate_invite_token!

          render json: {
            invite_token: @group.invite_token,
            invite_token_expires_at: @group.invite_token_expires_at.iso8601
          }, status: :ok
        rescue ActiveRecord::RecordInvalid => e
          render_validation_error(e.record)
        end

        private

        def set_group
          return if performed?

          @group = Group.find_by(public_id: params[:group_id])
          return if @group.present?

          render_not_found(
            reason: "group_not_found",
            detail: "Group not found"
          )
        end

        def authorize_owner!
          return if performed?
          return if @group.members.exists?(user: current_user, role: "OWNER", active: true)

          render_forbidden(
            reason: "forbidden",
            detail: "You are not allowed to regenerate invite token for this group"
          )
        end
      end
    end
  end
end
