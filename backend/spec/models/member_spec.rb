# frozen_string_literal: true

require "rails_helper"

RSpec.describe Member, type: :model do
  describe "バリデーション" do
    describe "正常系" do
      context "必須属性が揃っているとき" do
        subject(:member) { build(:member) }

        it "有効であること" do
          expect(member).to be_valid
        end
      end

      context "role を指定しないとき" do
        subject(:member) { build(:member) }

        it "デフォルトで MEMBER になること" do
          expect(member.role).to eq("MEMBER")
          expect(member).to be_valid
        end
      end
    end

    describe "異常系" do
      context "group がないとき" do
        subject(:member) { build(:member, group: nil) }

        it "無効であること" do
          expect(member).not_to be_valid
          expect(member.errors[:group]).to be_present
        end
      end

      context "user がないとき" do
        subject(:member) { build(:member, user: nil) }

        it "無効であること" do
          expect(member).not_to be_valid
          expect(member.errors[:user]).to be_present
        end
      end
    end
  end

  describe "制約" do
    describe "正常系" do
      context "同一 group 内で user が異なるとき" do
        let!(:group) { create(:group) }
        let!(:member1) { create(:member, group: group) }
        let!(:member2) { create(:member, group: group, user: create(:user)) }

        it "作成できること" do
          expect(member1).to be_persisted
          expect(member2).to be_persisted
        end
      end
    end

    describe "異常系" do
      context "同一 (group_id, user_id) を重複させたとき" do
        let!(:member) { create(:member) }
        let!(:duplicate) { build(:member, group: member.group, user: member.user) }

        it "無効であること（モデルバリデーション）" do
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:user_id]).to be_present
        end

        it "DBレベルでも重複が防がれること" do
          expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
        end
      end
    end
  end

  describe "関連" do
    subject(:member) { create(:member) }

    it "group に属すること" do
      expect(member.group).to be_present
    end

    it "user に属すること" do
      expect(member.user).to be_present
    end
  end
end
