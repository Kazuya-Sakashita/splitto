# frozen_string_literal: true

class User < ApplicationRecord
  before_validation :set_public_id, on: :create

  has_many :members, inverse_of: :user, dependent: :destroy
  has_many :groups, through: :members

  validates :external_uid, presence: true, uniqueness: true
  validates :public_id, presence: true, uniqueness: true, length: { is: 26 }

  private

  def set_public_id
    return if public_id.present?

    self.public_id = generate_unique_public_id
  end

  def generate_unique_public_id
    10.times do
      candidate = generate_public_id
      return candidate unless self.class.exists?(public_id: candidate)
    end

    raise "failed to generate unique public_id"
  end

  def generate_public_id
    # ulid が使えるなら 26文字固定でよい
    return SecureRandom.ulid if SecureRandom.respond_to?(:ulid)

    # 26文字固定
    SecureRandom.alphanumeric(26)
  end
end
