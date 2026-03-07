# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/invites/:invite_token/join", type: :request do
  let!(:invite_token) { "join_token_123" }
  let!(:group) { create(:group, invite_token: invite_token, name: "大阪旅行") }

  context "認証成功時" do
    let!(:external_uid) { "clerk_user_123" }
    let!(:token) { "test-token" }
    let!(:headers) { { "Authorization" => "Bearer #{token}" } }
    let!(:user) { create(:user, external_uid: external_uid) }

    before do
      allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
        { "sub" => external_uid }
      )
    end

    context "正常系" do
      it "招待リンクから参加できる" do
        post "/api/v1/invites/#{invite_token}/join", headers: headers

        expect(response).to have_http_status(:ok)

        body = response.parsed_body
        created_member = Member.find_by!(group: group, user: user)

        aggregate_failures do
          expect(body.dig("group", "id")).to eq(group.public_id)
          expect(body.dig("group", "name")).to eq("大阪旅行")
          expect(body.dig("group", "members_count")).to eq(1)

          expect(body.dig("member", "id")).to eq(created_member.id)
          expect(body.dig("member", "role")).to eq("MEMBER")
          expect(body.dig("member", "active")).to eq(true)
          expect(body.dig("member", "joined_at")).to be_present
        end
      end

      it "members レコードが作成される" do
        expect do
          post "/api/v1/invites/#{invite_token}/join", headers: headers
        end.to change(Member, :count).by(1)

        created_member = Member.find_by!(group: group, user: user)

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(created_member.role).to eq("MEMBER")
          expect(created_member.active).to eq(true)
          expect(created_member.joined_at).to be_present
          expect(created_member.left_at).to be_nil
        end
      end
    end

    context "冪等" do
      let!(:existing_member) do
        create(
          :member,
          group: group,
          user: user,
          role: "MEMBER",
          active: true,
          joined_at: 1.day.ago
        )
      end

      it "既に参加済みでもエラーにならない" do
        expect do
          post "/api/v1/invites/#{invite_token}/join", headers: headers
        end.not_to change(Member, :count)

        body = response.parsed_body

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(body.dig("group", "id")).to eq(group.public_id)
          expect(body.dig("member", "id")).to eq(existing_member.id)
          expect(body.dig("member", "role")).to eq("MEMBER")
          expect(body.dig("member", "active")).to eq(true)
        end
      end
    end

    context "再参加" do
      let!(:inactive_member) do
        create(
          :member,
          group: group,
          user: user,
          role: "MEMBER",
          active: false,
          joined_at: 3.days.ago,
          left_at: 1.day.ago
        )
      end

      it "inactive member は再参加できる" do
        previous_joined_at = inactive_member.joined_at

        expect do
          post "/api/v1/invites/#{invite_token}/join", headers: headers
        end.not_to change(Member, :count)

        inactive_member.reload
        body = response.parsed_body

        aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(inactive_member.active).to eq(true)
          expect(inactive_member.left_at).to be_nil
          expect(inactive_member.joined_at).to be_present
          expect(inactive_member.joined_at).not_to eq(previous_joined_at)

          expect(body.dig("group", "id")).to eq(group.public_id)
          expect(body.dig("member", "id")).to eq(inactive_member.id)
          expect(body.dig("member", "role")).to eq("MEMBER")
          expect(body.dig("member", "active")).to eq(true)
          expect(body.dig("member", "joined_at")).to be_present
        end
      end
    end

    context "異常系" do
      it "無効トークンなら404を返す" do
        post "/api/v1/invites/invalid_token/join", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(response.media_type).to eq("application/problem+json")

        body = response.parsed_body

        aggregate_failures do
          expect(body["title"]).to eq("Not Found")
          expect(body["status"]).to eq(404)
          expect(body["reason"]).to eq("invalid_invite_token")
          expect(body["detail"]).to eq("invite_token is invalid")
        end
      end
    end
  end

  context "認証失敗時" do
    it "401を返す" do
      post "/api/v1/invites/#{invite_token}/join"

      expect(response).to have_http_status(:unauthorized)
      expect(response.media_type).to eq("application/problem+json")

      body = response.parsed_body

      aggregate_failures do
        expect(body["title"]).to eq("Unauthorized")
        expect(body["status"]).to eq(401)
        expect(body["reason"]).to be_present
      end
    end
  end
end
