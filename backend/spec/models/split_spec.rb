# frozen_string_literal: true

require "rails_helper"

RSpec.describe Split, type: :model do
  describe "バリデーション" do
    let!(:group)   { create(:group) }
    let!(:user)    { create(:user) }
    let!(:expense) do
      create(
        :expense,
        group: group,
        paid_by: user,
        created_by: user,
        amount_cents: 1000,
        splits: [Split.new(user: user, share_cents: 1000)]
      )
    end

    describe "異常系" do
      context "share_cents が負のとき" do
        subject(:split) { build(:split, expense: expense, user: user, share_cents: -1) }

        it "無効であること" do
          expect(split).to be_invalid
          expect(split.errors[:share_cents]).to be_present
        end
      end

      context "同一 expense 内で user_id が重複するとき" do
        let!(:other_user) { create(:user) }

        before do
          # expense は既に user の split を 1 件持っている
          create(:split, expense: expense, user: other_user, share_cents: 0)
        end

        subject(:split) { build(:split, expense: expense, user: user, share_cents: 0) }

        it "無効であること" do
          expect(split).to be_invalid
          expect(split.errors[:user_id]).to be_present
        end
      end

      context "share_percent が範囲外（>100）のとき" do
        subject(:split) { build(:split, expense: expense, user: user, share_percent: 101) }

        it "無効であること" do
          expect(split).to be_invalid
          expect(split.errors[:share_percent]).to be_present
        end
      end
    end
  end
end
