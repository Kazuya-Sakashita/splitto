# frozen_string_literal: true

module Me
  class SharedGroupUsersQuery
    def initialize(user)
      @user = user
    end

    def call
      shared_group_members
        .select(*select_columns)
        .group(*group_columns)
        .order(last_together_at_desc)
        .order(users_public_id_asc)
    end

    private

    attr_reader :user

    def shared_group_members
      Member
        .joins(:user)
        .where(group_id: joined_group_ids)
        .where.not(user_id: user.id)
    end

    def joined_group_ids
      user.members.select(:group_id)
    end

    def select_columns
      [
        "users.public_id AS public_user_id",
        "MAX(members.updated_at) AS last_together_at"
      ]
    end

    def group_columns
      [
        "members.user_id",
        "users.public_id"
      ]
    end

    def last_together_at_desc
      Arel.sql("MAX(members.updated_at) DESC")
    end

    def users_public_id_asc
      "users.public_id ASC"
    end
  end
end
