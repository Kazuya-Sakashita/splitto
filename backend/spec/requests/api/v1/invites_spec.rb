# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invites API", type: :request do
  describe "GET /api/v1/invites/:invite_token" do
    let(:invite_token) { "token_123" }
    let(:owner) { create(:user) }
    let!(:group) { create(:group, invite_token: invite_token, name: "大阪旅行") }

    before do
      create(:member, group: group, user: owner, role: "OWNER", active: true, joined_at: Time.current)
    end

    context "正常系" do
      it "招待トークンでグループ情報を取得できる" do
        get "/api/v1/invites/#{invite_token}"

        expect(response).to have_http_status(:ok)
        body = response.parsed_body

        expect(body).to have_key("group")
        expect(body.dig("group", "id")).to eq(group.public_id)
        expect(body.dig("group", "name")).to eq("大阪旅行")
        expect(body.dig("group", "members_count")).to eq(1)
      end
    end

    context "異常系" do
      it "無効トークンで404（RFC9457）を返す" do
        get "/api/v1/invites/invalid_token"

        expect(response).to have_http_status(:not_found)
        expect(response.media_type).to eq("application/problem+json")

        body = response.parsed_body
        expect(body["title"]).to eq("Not Found")
        expect(body["status"]).to eq(404)
        expect(body["reason"]).to eq("invalid_invite_token")
        expect(body["detail"]).to eq("invite_token is invalid")
      end
    end
  end
end
