# frozen_string_literal: true

class Group < ApplicationRecord
  class MemberAlreadyExistsError < StandardError; end

  has_many :members, inverse_of: :group, dependent: :destroy
  has_many :users, through: :members

  before_validation :ensure_public_id, on: :create
  before_validation :ensure_invite_token, on: :create

  validates :public_id, presence: true, uniqueness: true, length: { is: 26 }
  validates :name, presence: true
  validates :currency, presence: true
  validates :invite_token, presence: true, uniqueness: true

  def join_or_rejoin!(user)
    existing_member = members.find_by(user: user)
    return existing_member.rejoin! if existing_member.present?

    members.create!(
      user: user,
      role: "MEMBER",
      active: true,
      joined_at: Time.current,
      left_at: nil
    )
  end

  def add_member!(user_public_id:)
    transaction do
      user = User.find_by!(public_id: user_public_id)

      if members.exists?(user_id: user.id)
        raise MemberAlreadyExistsError, "User is already a member of this group"
      end

      members.create!(
        user: user,
        role: "MEMBER",
        active: true,
        joined_at: Time.current
      )
    end
  rescue ActiveRecord::RecordNotUnique
    raise MemberAlreadyExistsError, "User is already a member of this group"
  end

  private

  def ensure_public_id
    return if public_id.present?

    self.public_id = loop do
      candidate = SecureRandom.base58(26)
      break candidate unless self.class.exists?(public_id: candidate)
    end
  end

  def ensure_invite_token
    return if invite_token.present?

    self.invite_token = loop do
      candidate = SecureRandom.base58(32)
      break candidate unless self.class.exists?(invite_token: candidate)
    end
  end
end
