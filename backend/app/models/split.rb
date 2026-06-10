# frozen_string_literal: true

class Split < ApplicationRecord
  belongs_to :expense, inverse_of: :splits
  belongs_to :user

  validates :share_cents, presence: true,
                          numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :expense_id }
  validates :share_percent,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
end
