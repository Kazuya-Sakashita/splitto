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

      def join
        group = find_group_by_invite_token!

        member = ActiveRecord::Base.transaction do
          join_group!(group)
        end

        render json: {
          group: group_response(group),
          member: member_response(member)
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render_invalid_invite_token
      rescue ActiveRecord::RecordInvalid => e
        render_unprocessable_entity(detail: e.record.errors.full_messages.join(", "))
      end

      private

      def find_group_by_invite_token!
        Group.find_by!(invite_token: params[:invite_token])
      end

      def join_group!(group)
        existing_member = group.members.find_by(user: current_user)
        return rejoin_member!(existing_member) if existing_member.present?

        group.members.create!(
          user: current_user,
          role: "MEMBER",
          active: true,
          joined_at: Time.current
        )
      end

      def rejoin_member!(member)
        return member if member.active?

        member.update!(
          active: true,
          left_at: nil,
          joined_at: Time.current
        )

        member
      end

      def group_response(group)
        {
          id: group.public_id,
          name: group.name,
          members_count: group.members.where(active: true).count
        }
      end

      def member_response(member)
        {
          id: member.id,
          role: member.role,
          active: member.active,
          joined_at: member.joined_at
        }
      end

      def render_invalid_invite_token
        render_not_found(reason: "invalid_invite_token", detail: "invite_token is invalid")
      end
    end
  end
end
