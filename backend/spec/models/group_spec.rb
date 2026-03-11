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

  describe "#add_member!" do
    let!(:group) { create(:group) }
    let!(:target_user) { create(:user) }

    context "追加対象ユーザーが存在するとき" do
      it "メンバーを追加すること" do
        expect do
          group.add_member!(user_public_id: target_user.public_id)
        end.to change(group.members, :count).by(1)
      end

      it "追加した member を返すこと" do
        member = group.add_member!(user_public_id: target_user.public_id)

        expect(member).to be_a(Member)
        expect(member.group).to eq(group)
        expect(member.user).to eq(target_user)
      end

      it "MEMBER ロールで追加すること" do
        member = group.add_member!(user_public_id: target_user.public_id)

        expect(member.role).to eq("MEMBER")
      end

      it "active=true で追加すること" do
        member = group.add_member!(user_public_id: target_user.public_id)

        expect(member.active).to be(true)
      end

      it "joined_at を設定すること" do
        member = group.add_member!(user_public_id: target_user.public_id)

        expect(member.joined_at).to be_present
      end
    end

    context "追加対象ユーザーが存在しないとき" do
      it "ActiveRecord::RecordNotFound を発生させること" do
        expect do
          group.add_member!(user_public_id: "usr_not_found")
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "メンバーを追加しないこと" do
        expect do
          begin
            group.add_member!(user_public_id: "usr_not_found")
          rescue ActiveRecord::RecordNotFound
            nil
          end
        end.not_to change(group.members, :count)
      end
    end

    context "追加対象ユーザーがすでにメンバーのとき" do
      before do
        create(
          :member,
          group: group,
          user: target_user,
          role: "MEMBER",
          active: true,
          joined_at: Time.current
        )
      end

      it "Group::MemberAlreadyExistsError を発生させること" do
        expect do
          group.add_member!(user_public_id: target_user.public_id)
        end.to raise_error(Group::MemberAlreadyExistsError)
      end

      it "メンバーを追加しないこと" do
        expect do
          begin
            group.add_member!(user_public_id: target_user.public_id)
          rescue Group::MemberAlreadyExistsError
            nil
          end
        end.not_to change(group.members, :count)
      end
    end
  end
end
