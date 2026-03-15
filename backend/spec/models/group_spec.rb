# frozen_string_literal: true

require "rails_helper"

RSpec.describe Group, type: :model do
  describe "バリデーション" do
    context "必須属性が揃っているとき" do
      let!(:group) { build(:group) }

      it "有効であること" do
        expect(group).to be_valid
      end
    end

    context "name がないとき" do
      let!(:group) { build(:group, name: nil) }

      before do
        group.valid?
      end

      it "無効であること" do
        expect(group).not_to be_valid
      end

      it "name のエラーが入っていること" do
        expect(group.errors[:name]).to be_present
      end
    end
  end

  describe "関連" do
    context "members" do
      let!(:assoc) { described_class.reflect_on_association(:members) }

      it "members を持つこと" do
        expect(assoc).to be_present
        expect(assoc.macro).to eq(:has_many)
        expect(assoc.class_name).to eq("Member")
      end
    end

    context "users（members 経由）" do
      let!(:assoc) { described_class.reflect_on_association(:users) }

      it "users を持つこと（members 経由）" do
        expect(assoc).to be_present
        expect(assoc.macro).to eq(:has_many)
        expect(assoc.options[:through]).to eq(:members)
        expect(assoc.class_name).to eq("User")
      end
    end
  end

  describe "#join_or_rejoin!" do
    let!(:group) { create(:group) }
    let!(:target_user) { create(:user) }

    context "対象ユーザーが未参加のとき" do
      it "メンバーを追加すること" do
        expect do
          group.join_or_rejoin!(target_user)
        end.to change(group.members, :count).by(1)
      end

      it "追加した member を返すこと" do
        member = group.join_or_rejoin!(target_user)

        expect(member).to be_a(Member)
        expect(member.group).to eq(group)
        expect(member.user).to eq(target_user)
      end

      it "MEMBER ロールで追加すること" do
        member = group.join_or_rejoin!(target_user)

        expect(member.role).to eq("MEMBER")
      end

      it "active=true で追加すること" do
        member = group.join_or_rejoin!(target_user)

        expect(member.active).to be(true)
      end

      it "joined_at を設定すること" do
        member = group.join_or_rejoin!(target_user)

        expect(member.joined_at).to be_present
      end

      it "left_at を nil にすること" do
        member = group.join_or_rejoin!(target_user)

        expect(member.left_at).to be_nil
      end
    end

    context "対象ユーザーが退出済みメンバーのとき" do
      let!(:member) do
        create(
          :member,
          group: group,
          user: target_user,
          role: "MEMBER",
          active: false,
          joined_at: 2.days.ago,
          left_at: 1.day.ago
        )
      end

      it "メンバー数が増えないこと" do
        member

        expect do
          group.join_or_rejoin!(target_user)
        end.not_to change(group.members, :count)
      end

      it "既存 member を返すこと" do
        returned_member = group.join_or_rejoin!(target_user)

        expect(returned_member).to eq(member)
      end

      it "再参加状態にすること" do
        returned_member = group.join_or_rejoin!(target_user)

        expect(returned_member.active).to be(true)
        expect(returned_member.left_at).to be_nil
      end
    end

    context "対象ユーザーがすでに active なメンバーのとき" do
      let!(:member) do
        create(
          :member,
          group: group,
          user: target_user,
          role: "MEMBER",
          active: true,
          joined_at: Time.current,
          left_at: nil
        )
      end

      it "メンバー数が増えないこと" do
        member

        expect do
          group.join_or_rejoin!(target_user)
        end.not_to change(group.members, :count)
      end

      it "既存 member を返すこと" do
        returned_member = group.join_or_rejoin!(target_user)

        expect(returned_member).to eq(member)
      end
    end

    context "member 作成時に競合が発生したとき" do
      let!(:existing_member) do
        create(
          :member,
          group: group,
          user: target_user,
          role: "MEMBER",
          active: true,
          joined_at: Time.current,
          left_at: nil
        )
      end

      before do
        association = group.members

        allow(association).to receive(:find_by).with(user: target_user).and_return(nil)
        allow(association).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
        allow(association).to receive(:find_by!).with(user: target_user).and_return(existing_member)
      end

      it "既存 member を再取得して返すこと" do
        returned_member = group.join_or_rejoin!(target_user)

        expect(returned_member).to eq(existing_member)
      end
    end
  end

  describe "#invite_token_active?" do
    around do |example|
      freeze_time { example.run }
    end

    context "有効期限内のとき" do
      let!(:group) { build(:group, invite_token_expires_at: 24.hours.from_now) }

      it "true を返すこと" do
        expect(group.invite_token_active?).to be(true)
      end
    end

    context "有効期限切れのとき" do
      let!(:group) { build(:group, invite_token_expires_at: 1.second.ago) }

      it "false を返すこと" do
        expect(group.invite_token_active?).to be(false)
      end
    end

    context "invite_token_expires_at が nil のとき" do
      let!(:group) { build(:group, invite_token_expires_at: nil) }

      it "false を返すこと" do
        expect(group.invite_token_active?).to be(false)
      end
    end
  end

  describe "作成時の invite_token_expires_at 設定" do
    around do |example|
      freeze_time { example.run }
    end

    context "invite_token_expires_at を指定しないとき" do
      let!(:group) { create(:group, invite_token_expires_at: nil) }

      it "invite_token_expires_at が設定されること" do
        expect(group.invite_token_expires_at).to be_present
      end

      it "24時間後の値が設定されること" do
        expect(group.invite_token_expires_at).to eq(24.hours.from_now)
      end
    end

    context "invite_token_expires_at を指定するとき" do
      let!(:expires_at) { 3.days.from_now }
      let!(:group) { create(:group, invite_token_expires_at: expires_at) }

      it "指定した値が保持されること" do
        expect(group.invite_token_expires_at).to eq(expires_at)
      end
    end
  end
end
