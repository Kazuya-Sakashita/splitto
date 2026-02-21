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
end
