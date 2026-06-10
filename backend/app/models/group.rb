# frozen_string_literal: true

class Group < ApplicationRecord
  INVITE_TOKEN_EXPIRES_IN = 24.hours

  has_many :members, inverse_of: :group, dependent: :destroy
  has_many :users, through: :members
  has_many :expenses, inverse_of: :group

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

    members.create_or_find_by!(user: user) do |member|
      member.role = "MEMBER"
      member.active = true
      member.joined_at = Time.current
      member.left_at = nil
    end
  end

  # 支払いを追加する。
  # - 全 user（payer / creator / splits の user）が active member であることを検証
  # - expense と splits を atomic に作成
  # - エラーは ActiveRecord::RecordInvalid として raise（controller でハンドリング）
  def add_expense!(payer:, creator:, amount_cents:, paid_on:, split_type:, splits_payload:, category: nil, note: nil)
    ActiveRecord::Base.transaction do
      active_user_ids = members.where(active: true).pluck(:user_id).to_set

      raise_invalid_member(:paid_by, payer)     unless active_user_ids.include?(payer.id)
      raise_invalid_member(:created_by, creator) unless active_user_ids.include?(creator.id)

      splits_payload.each do |s|
        raise_invalid_member(:splits, s[:user]) unless active_user_ids.include?(s[:user].id)
      end

      expense = expenses.create!(
        paid_by: payer,
        created_by: creator,
        amount_cents: amount_cents,
        paid_on: paid_on,
        split_type: split_type,
        category: category,
        note: note,
        splits: splits_payload.map { |s|
          Split.new(user: s[:user], share_cents: s[:share_cents], share_percent: s[:share_percent])
        }
      )

      expense
    end
  end

  def regenerate_invite_token!
    update!(
      invite_token: generate_unique_invite_token,
      invite_token_expires_at: Time.current + INVITE_TOKEN_EXPIRES_IN
    )
  end

  def invite_token_active?
    invite_token_expires_at.present? && invite_token_expires_at > Time.current
  end

  private

  def raise_invalid_member(field, user)
    expense = Expense.new
    expense.errors.add(field, :not_group_member, user_id: user&.public_id)
    raise ActiveRecord::RecordInvalid, expense
  end

  def ensure_public_id
    return if public_id.present?

    self.public_id = loop do
      candidate = SecureRandom.base58(26)
      break candidate unless self.class.exists?(public_id: candidate)
    end
  end

  def ensure_invite_token
    return if invite_token.present?

    self.invite_token = generate_unique_invite_token
  end

  def ensure_invite_token_expires_at
    return if invite_token_expires_at.present?

    self.invite_token_expires_at = Time.current + INVITE_TOKEN_EXPIRES_IN
  end

  def generate_unique_invite_token
    loop do
      candidate = SecureRandom.base58(32)
      break candidate unless self.class.exists?(invite_token: candidate)
    end
  end
end
