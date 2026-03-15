# frozen_string_literal: true

class Group < ApplicationRecord
  INVITE_TOKEN_EXPIRES_IN = 24.hours

  has_many :members, inverse_of: :group, dependent: :destroy
  has_many :users, through: :members

  before_validation :ensure_public_id, on: :create
  before_validation :ensure_invite_token, on: :create
  before_validation :ensure_invite_token_expires_at, on: :create

  validates :public_id, presence: true, uniqueness: true, length: { is: 26 }
  validates :name, presence: true
  validates :currency, presence: true
  validates :invite_token, presence: true, uniqueness: true
  validates :invite_token_expires_at, presence: true

  def join_or_rejoin!(user)
    existing_member = members.find_by(user: user)

    return existing_member if existing_member&.active?
    return existing_member.rejoin! if existing_member.present?

    begin
      members.create!(
        user: user,
        role: "MEMBER",
        active: true,
        joined_at: Time.current,
        left_at: nil
      )
    rescue ActiveRecord::RecordNotUnique
      members.find_by!(user: user)
    end
  end

  def invite_token_active?
    invite_token_expires_at.present? && invite_token_expires_at > Time.current
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

  def ensure_invite_token_expires_at
    return if invite_token_expires_at.present?

    self.invite_token_expires_at = Time.current + INVITE_TOKEN_EXPIRES_IN
  end
end
