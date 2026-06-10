# frozen_string_literal: true

class Api::V1::Groups::ExpensesController < ApplicationController
  before_action :set_group
  before_action :authorize_active_member!

  def create
    payer = User.find_by(public_id: expense_params[:paid_by_id])
    return render_invalid_payer if payer.nil?

    splits_payload, invalid_user_id = build_splits_payload(expense_params[:splits])
    return render_invalid_split_member(invalid_user_id) if invalid_user_id

    expense = @group.add_expense!(
      payer: payer,
      creator: current_user,
      amount_cents: expense_params[:amount_cents],
      paid_on: expense_params[:paid_on],
      split_type: expense_params[:split_type],
      category: expense_params[:category],
      note: expense_params[:note],
      splits_payload: splits_payload
    )

    render json: expense_response(expense), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render_record_invalid(e.record)
  end

  private

  def set_group
    @group = Group.find_by(public_id: params[:group_id])
    return if @group.present?

    render_not_found(reason: "group_not_found", detail: "Group not found")
  end

  def authorize_active_member!
    return if @group.members.exists?(user: current_user, active: true)

    render_forbidden(
      reason: "not_group_member",
      detail: "You are not a member of this group"
    )
  end

  def expense_params
    params.permit(
      :paid_by_id,
      :created_by_id,
      :amount_cents,
      :paid_on,
      :category,
      :note,
      :split_type,
      splits: %i[user_id share_cents share_percent]
    )
  end

  # splits_payload を user オブジェクト解決済みの配列に変換する。
  # 解決できない user_id が混ざっていた場合は [nil, invalid_user_id] を返す。
  def build_splits_payload(splits_param)
    splits = Array(splits_param).map(&:to_h)
    return [[], nil] if splits.empty?

    public_ids = splits.map { |s| s["user_id"] || s[:user_id] }
    users_by_public_id = User.where(public_id: public_ids).index_by(&:public_id)

    payload = []
    splits.each do |s|
      pid = s["user_id"] || s[:user_id]
      user = users_by_public_id[pid]
      return [nil, pid] if user.nil?

      payload << {
        user: user,
        share_cents: s["share_cents"] || s[:share_cents],
        share_percent: s["share_percent"] || s[:share_percent]
      }
    end

    [payload, nil]
  end

  def render_invalid_payer
    render_unprocessable_entity(
      reason: "invalid_payer",
      detail: "paid_by_id must reference an active group member"
    )
  end

  def render_invalid_split_member(user_id)
    render_unprocessable_entity(
      reason: "invalid_split_member",
      detail: "splits contains a user_id that does not exist: #{user_id}"
    )
  end

  # Group#add_expense! 内で active member 違反等が起きると Expense.errors にキーが追加され
  # ActiveRecord::RecordInvalid として raise される。errors の key に応じて reason を分岐する。
  def render_record_invalid(record)
    return render_invalid_payer    if record.errors[:paid_by].any?
    return render_invalid_creator  if record.errors[:created_by].any?
    return render_invalid_splits   if record.errors[:splits].any? && record.errors.details[:splits].any? { |d| d[:error] == :not_group_member }

    render_validation_error(record)
  end

  def render_invalid_creator
    render_unprocessable_entity(
      reason: "invalid_creator",
      detail: "created_by must be an active group member"
    )
  end

  def render_invalid_splits
    render_unprocessable_entity(
      reason: "invalid_split_member",
      detail: "splits contains a user that is not an active group member"
    )
  end

  def expense_response(expense)
    {
      expense: expense_json(expense),
      splits: expense.splits.map { |s| split_json(s) },
      attachments: []
    }
  end

  def expense_json(expense)
    {
      id: expense.public_id,
      group_id: expense.group.public_id,
      paid_by_id: expense.paid_by.public_id,
      created_by_id: expense.created_by.public_id,
      amount_cents: expense.amount_cents,
      paid_on: expense.paid_on.iso8601,
      category: expense.category,
      note: expense.note,
      split_type: expense.split_type,
      deleted_at: expense.deleted_at&.iso8601,
      created_at: expense.created_at&.iso8601,
      updated_at: expense.updated_at&.iso8601
    }
  end

  def split_json(split)
    {
      id: split.id.to_s,
      expense_id: split.expense.public_id,
      user_id: split.user.public_id,
      share_cents: split.share_cents,
      share_percent: split.share_percent,
      created_at: split.created_at&.iso8601,
      updated_at: split.updated_at&.iso8601
    }
  end
end
