# app/models/group.rb
class Group < ApplicationRecord
  has_many :members, inverse_of: :group, dependent: :destroy
  has_many :users, through: :members

  before_validation :ensure_public_id, on: :create
  before_validation :ensure_invite_token, on: :create

  validates :public_id, presence: true, uniqueness: true, length: { is: 26 }
  validates :name, presence: true
  validates :currency, presence: true
  validates :invite_token, presence: true, uniqueness: true

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
