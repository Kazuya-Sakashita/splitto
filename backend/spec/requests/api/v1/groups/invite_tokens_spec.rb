# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PATCH /api/v1/groups/:group_id/invite_token", type: :request do
  let!(:token) { "test-token" }
  let!(:headers) { { "Authorization" => "Bearer #{token}" } }

  let!(:owner) { create(:user) }
  let!(:member_user) { create(:user) }
  let!(:group) do
    create(
      :group,
      public_id: "12345678901234567890123456",
      invite_token: "old_invite_token",
      invite_token_expires_at: 12.hours.from_now
    )
  end
  let!(:owner_member) do
    create(
      :member,
      group: group,
      user: owner,
      role: Member::ROLE_OWNER,
      active: true,
      joined_at: Time.current
    )
  end

  subject(:do_request) do
    patch "/api/v1/groups/#{target_group_id}/invite_token", headers: request_headers
  end

  let!(:target_group_id) { group.public_id }
  let!(:request_headers) { headers }

  context "認証成功時" do
    context "実行ユーザーがオーナーのとき" do
      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => owner.external_uid }
        )
      end

      it "招待トークンを再生成できること" do
        old_token = group.invite_token
        old_expires_at = group.invite_token_expires_at

        do_request

        expect(response).to have_http_status(:ok), response.body
        assert_response_schema_confirm(200)

        body = JSON.parse(response.body)
        group.reload

        expect(response.content_type).to include("application/json")
        expect(body["invite_token"]).to eq(group.invite_token)
        expect(body["invite_token_expires_at"]).to eq(group.invite_token_expires_at.iso8601)
        expect(body["invite_token"]).to be_present
        expect(body["invite_token_expires_at"]).to be_present
        expect(group.invite_token).not_to eq(old_token)
        expect(group.invite_token_expires_at).to be > old_expires_at
      end

      it "再生成後は旧トークンで招待確認APIにアクセスできないこと" do
        old_token = group.invite_token

        do_request

        expect(response).to have_http_status(:ok), response.body
        assert_response_schema_confirm(200)

        get "/api/v1/invites/#{old_token}"

        expect(response).to have_http_status(:not_found), response.body
      end

      it "再生成後は新トークンで招待確認APIにアクセスできること" do
        do_request

        expect(response).to have_http_status(:ok), response.body
        assert_response_schema_confirm(200)

        new_token = JSON.parse(response.body)["invite_token"]

        get "/api/v1/invites/#{new_token}"

        expect(response).to have_http_status(:ok), response.body
      end
    end

    context "実行ユーザーがオーナーではないとき" do
      let!(:member_record) do
        create(
          :member,
          group: group,
          user: member_user,
          role: Member::ROLE_MEMBER,
          active: true,
          joined_at: Time.current
        )
      end

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => member_user.external_uid }
        )
      end

      it "403を返すこと" do
        do_request

        expect(response).to have_http_status(:forbidden), response.body
        assert_response_schema_confirm(403)

        body = JSON.parse(response.body)
        expect(response.content_type).to include("application/problem+json")
        expect(body["title"]).to eq("Forbidden")
        expect(body["status"]).to eq(403)
        expect(body["reason"]).to eq("forbidden")
        expect(body["detail"]).to be_present
      end
    end

    context "実行ユーザーが active: false の元オーナーのとき" do
      let!(:inactive_owner_user) { create(:user) }
      let!(:inactive_owner_member) do
        create(
          :member,
          group: group,
          user: inactive_owner_user,
          role: Member::ROLE_OWNER,
          active: false,
          joined_at: 2.days.ago,
          left_at: 1.day.ago
        )
      end

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => inactive_owner_user.external_uid }
        )
      end

      it "403を返すこと" do
        do_request

        expect(response).to have_http_status(:forbidden), response.body
        assert_response_schema_confirm(403)

        body = JSON.parse(response.body)
        expect(response.content_type).to include("application/problem+json")
        expect(body["title"]).to eq("Forbidden")
        expect(body["status"]).to eq(403)
        expect(body["reason"]).to eq("forbidden")
        expect(body["detail"]).to be_present
      end
    end

    context "実行ユーザーがグループの非メンバーユーザーのとき" do
      let!(:non_member_user) { create(:user) }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => non_member_user.external_uid }
        )
      end

      it "403を返すこと" do
        do_request

        expect(response).to have_http_status(:forbidden), response.body
        assert_response_schema_confirm(403)

        body = JSON.parse(response.body)
        expect(response.content_type).to include("application/problem+json")
        expect(body["title"]).to eq("Forbidden")
        expect(body["status"]).to eq(403)
        expect(body["reason"]).to eq("forbidden")
        expect(body["detail"]).to be_present
      end
    end

    context "グループが存在しないとき" do
      let!(:target_group_id) { "not_found_group_id_123456" }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => owner.external_uid }
        )
      end

      it "404を返すこと" do
        do_request

        expect(response).to have_http_status(:not_found), response.body
        assert_response_schema_confirm(404)

        body = JSON.parse(response.body)
        expect(response.content_type).to include("application/problem+json")
        expect(body["title"]).to eq("Not Found")
        expect(body["status"]).to eq(404)
        expect(body["reason"]).to eq("group_not_found")
        expect(body["detail"]).to be_present
      end
    end
  end

  context "未認証のとき" do
    let!(:request_headers) { {} }

    it "401を返すこと" do
      do_request

      expect(response).to have_http_status(:unauthorized), response.body
      assert_response_schema_confirm(401)

      body = JSON.parse(response.body)
      expect(response.content_type).to include("application/problem+json")
      expect(body["title"]).to eq("Unauthorized")
      expect(body["status"]).to eq(401)
      expect(body["reason"]).to eq("missing_token")
      expect(body["detail"]).to be_present
    end
  end
end
