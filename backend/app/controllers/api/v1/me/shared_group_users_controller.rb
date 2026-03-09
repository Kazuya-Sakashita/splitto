# frozen_string_literal: true

module Api
  module V1
    module Me
      class SharedGroupUsersController < ApplicationController
        def index
          render json: { shared_group_users: serialized_shared_group_users }, status: :ok
        end

        private

        def shared_group_users
          ::Me::SharedGroupUsersQuery.new(current_user).call
        end

        def serialized_shared_group_users
          shared_group_users.map do |shared_group_user|
            serialize_shared_group_user(shared_group_user)
          end
        end

        def serialize_shared_group_user(shared_group_user)
          {
            user_id: shared_group_user.public_user_id,
            last_together_at: shared_group_user.last_together_at.iso8601
          }
        end
      end
    end
  end
end
