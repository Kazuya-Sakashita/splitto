# frozen_string_literal: true

module Api
  module V1
    class InvitesController < ApplicationController
      skip_before_action :authenticate_with_clerk!, only: [:show]

      def show
        group = find_group_by_invite_token!

        render json: {
          group: group_response(group)
        }
      rescue ActiveRecord::RecordNotFound
        render_invalid_invite_token
      end

      private

      def find_group_by_invite_token!
        Group.find_by!(invite_token: params[:invite_token])
      end

      def group_response(group)
        {
          id: group.public_id,
          name: group.name,
          members_count: group.members.where(active: true).count
        }
      end

      def render_invalid_invite_token
        render_not_found(reason: "invalid_invite_token", detail: "invite_token is invalid")
      end
    end
  end
end
