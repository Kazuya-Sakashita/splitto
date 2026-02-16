class Member < ApplicationRecord
  belongs_to :group, inverse_of: :members
  belongs_to :user, inverse_of: :members

  ROLES = %w[OWNER MEMBER].freeze

  before_validation :ensure_joined_at, on: :create

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :active, inclusion: { in: [true, false] }
  validates :joined_at, presence: true
  validates :user_id, uniqueness: { scope: :group_id }

  private

  def ensure_joined_at
    self.joined_at ||= Time.current
  end
end
