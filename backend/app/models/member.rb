class Member < ApplicationRecord
  belongs_to :group, inverse_of: :members
  belongs_to :user, inverse_of: :members

  ROLES = %w[OWNER MEMBER].freeze

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :active, inclusion: { in: [true, false] }
  validates :joined_at, presence: true
  validates :user_id, uniqueness: { scope: :group_id }
end
