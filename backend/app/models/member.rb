# frozen_string_literal: true

class Member < ApplicationRecord
  scope :active, -> { where(active: true) }

  belongs_to :group, inverse_of: :members
  belongs_to :user, inverse_of: :members

  ROLES = %w[OWNER MEMBER].freeze
  ROLE_OWNER = "OWNER"
  ROLE_MEMBER = "MEMBER"

  before_validation :ensure_public_id, on: :create
  before_validation :ensure_joined_at, on: :create

  validates :public_id, presence: true, uniqueness: true, length: { is: 26 }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :active, inclusion: { in: [true, false] }
  validates :joined_at, presence: true
  validates :user_id, uniqueness: { scope: :group_id }

  def rejoin!
    return self if active?

    update!(
      active: true,
      left_at: nil,
      joined_at: Time.current
    )

    self
  end

  private

  def ensure_public_id
    return if public_id.present?

    self.public_id = loop do
      candidate = SecureRandom.base58(26)
      break candidate unless self.class.exists?(public_id: candidate)
    end
  end

  def ensure_joined_at
    self.joined_at ||= Time.current
  end
end
