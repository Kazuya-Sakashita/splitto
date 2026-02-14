require "rails_helper"

RSpec.describe Group, type: :model do
  describe "バリデーション" do
    context "必須属性が揃っているとき" do
      let(:group) { build(:group) }

      it "有効であること" do
        expect(group).to be_valid
      end
    end

    context "name がないとき" do
      let(:group) { build(:group, name: nil) }

      it "無効であること" do
        expect(group).not_to be_valid

        group.valid?
        expect(group.errors[:name]).to be_present
      end
    end
  end

  describe "関連" do
    it "members を持つこと" do
      assoc = described_class.reflect_on_association(:members)

      expect(assoc).to be_present
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.class_name).to eq("Member")
    end

    it "users を持つこと（members 経由）" do
      assoc = described_class.reflect_on_association(:users)

      expect(assoc).to be_present
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:through]).to eq(:members)
      expect(assoc.class_name).to eq("User")
    end
  end
end
