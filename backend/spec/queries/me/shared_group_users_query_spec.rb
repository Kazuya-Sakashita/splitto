# frozen_string_literal: true

require "rails_helper"

RSpec.describe Me::SharedGroupUsersQuery do
  describe "#call" do
    context "同じグループに所属したユーザーがいるとき" do
      let!(:user) { create(:user) }
      let!(:group) { create(:group) }
      let!(:other_group) { create(:group) }
      let!(:other_user) { create(:user) }
      let!(:unrelated_user) { create(:user) }

      let!(:my_member) do
        create(
          :member,
          user: user,
          group: group,
          updated_at: Time.zone.parse("2026-03-05 09:00:00")
        )
      end

      let!(:other_member) do
        create(
          :member,
          user: other_user,
          group: group,
          updated_at: Time.zone.parse("2026-03-05 10:00:00")
        )
      end

      let!(:unrelated_member) do
        create(
          :member,
          user: unrelated_user,
          group: other_group,
          updated_at: Time.zone.parse("2026-03-06 10:00:00")
        )
      end

      it "同じグループに所属したユーザーを返す" do
        result = described_class.new(user).call

        expect(result.map(&:public_user_id)).to eq([other_user.public_id])
      end
    end

    context "自分自身が同じグループに所属しているとき" do
      let!(:user) { create(:user) }
      let!(:group) { create(:group) }
      let!(:other_user) { create(:user) }

      let!(:my_member) do
        create(
          :member,
          user: user,
          group: group,
          updated_at: Time.zone.parse("2026-03-05 09:00:00")
        )
      end

      let!(:other_member) do
        create(
          :member,
          user: other_user,
          group: group,
          updated_at: Time.zone.parse("2026-03-05 10:00:00")
        )
      end

      it "自分自身を含まない" do
        result = described_class.new(user).call

        expect(result.map(&:public_user_id)).not_to include(user.public_id)
      end
    end

    context "同じユーザーが複数の共有グループに所属しているとき" do
      let!(:user) { create(:user) }
      let!(:group_a) { create(:group) }
      let!(:group_b) { create(:group) }
      let!(:other_user) { create(:user) }

      let!(:my_member_in_group_a) do
        create(
          :member,
          user: user,
          group: group_a,
          updated_at: Time.zone.parse("2026-03-01 09:00:00")
        )
      end

      let!(:my_member_in_group_b) do
        create(
          :member,
          user: user,
          group: group_b,
          updated_at: Time.zone.parse("2026-03-02 09:00:00")
        )
      end

      let!(:other_member_in_group_a) do
        create(
          :member,
          user: other_user,
          group: group_a,
          updated_at: Time.zone.parse("2026-03-03 10:00:00")
        )
      end

      let!(:other_member_in_group_b) do
        create(
          :member,
          user: other_user,
          group: group_b,
          updated_at: Time.zone.parse("2026-03-05 10:00:00")
        )
      end

      it "同じユーザーを1件に集約する" do
        result = described_class.new(user).call

        expect(result.to_a.size).to eq(1)
        expect(result.first.public_user_id).to eq(other_user.public_id)
      end

      it "last_together_at に最も新しい updated_at を返す" do
        result = described_class.new(user).call

        expect(result.first.last_together_at.iso8601).to eq(
          other_member_in_group_b.updated_at.iso8601
        )
      end
    end

    context "同じグループに所属した他ユーザーがいないとき" do
      let!(:user) { create(:user) }
      let!(:group) { create(:group) }

      let!(:my_member) do
        create(
          :member,
          user: user,
          group: group,
          updated_at: Time.zone.parse("2026-03-05 09:00:00")
        )
      end

      it "空の結果を返す" do
        result = described_class.new(user).call

        expect(result).to be_empty
      end
    end

    context "last_together_at が異なるユーザーがいるとき" do
      let!(:user) { create(:user) }
      let!(:group_a) { create(:group) }
      let!(:group_b) { create(:group) }
      let!(:older_user) { create(:user) }
      let!(:newer_user) { create(:user) }

      let!(:my_member_in_group_a) do
        create(
          :member,
          user: user,
          group: group_a,
          updated_at: Time.zone.parse("2026-03-01 09:00:00")
        )
      end

      let!(:my_member_in_group_b) do
        create(
          :member,
          user: user,
          group: group_b,
          updated_at: Time.zone.parse("2026-03-02 09:00:00")
        )
      end

      let!(:older_user_member) do
        create(
          :member,
          user: older_user,
          group: group_a,
          updated_at: Time.zone.parse("2026-03-03 10:00:00")
        )
      end

      let!(:newer_user_member) do
        create(
          :member,
          user: newer_user,
          group: group_b,
          updated_at: Time.zone.parse("2026-03-05 10:00:00")
        )
      end

      it "last_together_at の降順で返す" do
        result = described_class.new(user).call

        expect(result.map(&:public_user_id)).to eq(
          [newer_user.public_id, older_user.public_id]
        )
      end
    end
  end
end
