# frozen_string_literal: true

module Api
  module V1
    module Invites
      class MembershipsController < ApplicationController
        def create
          group = find_group_by_invite_token!
          member = group.join_or_rejoin!(current_user)

          render json: { member: member_response(member) }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_invalid_invite_token
        rescue ActiveRecord::RecordInvalid => e
          render_unprocessable_entity(detail: e.record.errors.full_messages.join(", "))
        rescue ActiveRecord::RecordNotUnique
          member = group.members.find_by!(user: current_user)
          render json: { member: member_response(member) }, status: :ok
        end

        private

        def find_group_by_invite_token!
          Group.find_by!(invite_token: params[:invite_token])
        end

        def member_response(member)
          {
            id: member.id,
            role: member.role,
            active: member.active,
            joined_at: member.joined_at&.iso8601,
            left_at: member.left_at&.iso8601,
            user: {
              public_id: member.user.public_id
            },
            group: {
              public_id: member.group.public_id,
              name: member.group.name,
              currency: member.group.currency
            }
          }
        end

        def render_invalid_invite_token
          render_not_found(
            reason: "invalid_invite_token",
            detail: "invite_token is invalid"
          )
        end
      end
    end
  end
end
