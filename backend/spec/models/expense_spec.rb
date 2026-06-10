# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expense, type: :model do
  describe "バリデーション" do
    let!(:group)   { create(:group) }
    let!(:user_a)  { create(:user) }
    let!(:user_b)  { create(:user) }

    describe "正常系" do
      context "必須属性が揃い、splits の合計が amount_cents と一致するとき" do
        subject(:expense) do
          build(:expense, group: group, paid_by: user_a, created_by: user_a).tap do |e|
            e.amount_cents = 1000
            e.splits = [
              Split.new(user: user_a, share_cents: 500),
              Split.new(user: user_b, share_cents: 500)
            ]
          end
        end

        it "有効であること" do
          expect(expense).to be_valid
        end
      end
    end

    describe "異常系" do
      context "amount_cents が 0 以下のとき" do
        subject(:expense) do
          build(:expense, group: group, paid_by: user_a, created_by: user_a, amount_cents: 0)
        end

        it "無効であること" do
          expect(expense).to be_invalid
          expect(expense.errors[:amount_cents]).to be_present
        end
      end

      context "split_type が enum 外のとき" do
        subject(:expense) do
          build(:expense, group: group, paid_by: user_a, created_by: user_a, split_type: "INVALID")
        end

        it "無効であること" do
          expect(expense).to be_invalid
          expect(expense.errors[:split_type]).to be_present
        end
      end

      context "splits の合計が amount_cents と一致しないとき" do
        subject(:expense) do
          build(:expense, group: group, paid_by: user_a, created_by: user_a).tap do |e|
            e.amount_cents = 1000
            e.splits = [
              Split.new(user: user_a, share_cents: 400),
              Split.new(user: user_b, share_cents: 500)
            ]
          end
        end

        it "無効であること" do
          expect(expense).to be_invalid
          expect(expense.errors[:splits]).to be_present
        end
      end
    end
  end

  describe "公開ID自動採番" do
    let!(:group)  { create(:group) }
    let!(:user)   { create(:user) }

    context "public_id を指定せず保存するとき" do
      subject(:expense) do
        Expense.new(
          group: group, paid_by: user, created_by: user,
          amount_cents: 100, paid_on: Date.current, split_type: "EQUAL_ALL",
          splits: [Split.new(user: user, share_cents: 100)]
        )
      end

      it "26文字の public_id が自動採番されること" do
        expect { expense.save! }.to change { expense.public_id }.from(nil)
        expect(expense.public_id.length).to eq(26)
      end
    end
  end
end
