# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invites API", type: :request do
  describe "GET /api/v1/invites/:invite_token" do
    let!(:invite_token) { "token_123" }

    context "有効な招待トークンのとき" do
      let!(:group) do
        create(
          :group,
          invite_token: invite_token,
          invite_token_expires_at: 24.hours.from_now,
          name: "大阪旅行"
        )
      end

      let!(:owner_member) do
        create(
          :member,
          group: group,
          role: "OWNER",
          active: true,
          joined_at: Time.current,
          left_at: nil
        )
      end

      let!(:active_member) do
        create(
          :member,
          group: group,
          role: "MEMBER",
          active: true,
          joined_at: Time.current,
          left_at: nil
        )
      end

      let!(:inactive_member) do
        create(
          :member,
          group: group,
          role: "MEMBER",
          active: false,
          joined_at: 2.days.ago,
          left_at: 1.day.ago
        )
      end

      it "200 を返すこと" do
        get "/api/v1/invites/#{invite_token}"

        expect(response).to have_http_status(:ok)
      end

      it "招待情報を返すこと" do
        get "/api/v1/invites/#{invite_token}"

        body = JSON.parse(response.body)

        expect(body).to eq(
          {
            "group" => {
              "id" => group.public_id,
              "name" => "大阪旅行",
              "members_count" => 2
            }
          }
        )
      end
    end

    context "存在しない招待トークンのとき" do
      it "404 を返すこと" do
        get "/api/v1/invites/not_found_token"

        expect(response).to have_http_status(:not_found)
      end

      it "Problem Details 形式のエラーレスポンスを返すこと" do
        get "/api/v1/invites/not_found_token"

        body = JSON.parse(response.body)

        expect(response.media_type).to eq("application/problem+json")
        expect(body["status"]).to eq(404)
        expect(body["reason"]).to eq("invalid_invite_token")
        expect(body["detail"]).to eq("invite_token is invalid")
      end
    end

    context "有効期限切れの招待トークンのとき" do
      let!(:group) do
        create(
          :group,
          invite_token: invite_token,
          invite_token_expires_at: 1.second.ago,
          name: "大阪旅行"
        )
      end

      it "404 を返すこと" do
        get "/api/v1/invites/#{invite_token}"

        expect(response).to have_http_status(:not_found)
      end

      it "Problem Details 形式のエラーレスポンスを返すこと" do
        get "/api/v1/invites/#{invite_token}"

        body = JSON.parse(response.body)

        expect(response.media_type).to eq("application/problem+json")
        expect(body["status"]).to eq(404)
        expect(body["reason"]).to eq("invalid_invite_token")
        expect(body["detail"]).to eq("invite_token is invalid")
      end
    end
  end
end
