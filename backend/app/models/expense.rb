# frozen_string_literal: true

class Expense < ApplicationRecord
  SPLIT_TYPES = %w[EQUAL_ALL EQUAL_SELECTED AMOUNT PERCENT].freeze

  belongs_to :group, inverse_of: :expenses
  belongs_to :paid_by, class_name: "User"
  belongs_to :created_by, class_name: "User"

  has_many :splits, inverse_of: :expense, dependent: :destroy

  before_validation :ensure_public_id, on: :create

  validates :public_id, presence: true, uniqueness: true, length: { is: 26 }
  validates :amount_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :paid_on, presence: true
  validates :split_type, presence: true, inclusion: { in: SPLIT_TYPES }
  validate  :splits_sum_matches_amount

  scope :not_deleted, -> { where(deleted_at: nil) }

  private

  def ensure_public_id
    return if public_id.present?

    self.public_id = loop do
      candidate = SecureRandom.base58(26)
      break candidate unless self.class.exists?(public_id: candidate)
    end
  end

  def splits_sum_matches_amount
    return if splits.blank?
    return if splits.sum(&:share_cents) == amount_cents

    errors.add(:splits, :sum_mismatch)
  end
end
