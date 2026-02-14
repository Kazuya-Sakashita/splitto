class Group < ApplicationRecord
  has_many :members, inverse_of: :group, dependent: :destroy
  has_many :users, through: :members

  validates :public_id, presence: true, uniqueness: true, length: { is: 26 }
  validates :name, presence: true
  validates :currency, presence: true
  validates :invite_token, presence: true, uniqueness: true
end
