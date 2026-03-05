# frozen_string_literal: true

module Api
  module V1
    class InvitesController < ApplicationController
      skip_before_action :authenticate_with_clerk!

      def show
        group = Group.find_by!(invite_token: params[:invite_token])

        render json: {
          group: {
            id: group.public_id,
            name: group.name,
            members_count: group.members.where(active: true).count
          }
        }
      rescue ActiveRecord::RecordNotFound
        render_not_found(reason: "invalid_invite_token", detail: "invite_token is invalid")
      end
    end
  end
end
