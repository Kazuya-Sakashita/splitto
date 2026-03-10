# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/me/shared_group_users", type: :request do
  describe "GET /api/v1/me/shared_group_users" do
    context "認証成功のとき" do
      let!(:external_uid) { "clerk_user_123" }
      let!(:token) { "test-token" }
      let!(:headers) { { "Authorization" => "Bearer #{token}" } }
      let!(:user) { create(:user, external_uid: external_uid) }

      let!(:group) { create(:group) }
      let!(:other_user) { create(:user) }

      let!(:my_member) do
        create(
          :member,
          user: user,
          group: group,
          updated_at: Time.zone.parse("2026-03-05 10:00:00")
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

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => external_uid }
        )
      end

      it "200を返し、レスポンスがOpenAPIスキーマに一致する" do
        get "/api/v1/me/shared_group_users", headers: headers

        expect(response).to have_http_status(:ok)
        assert_response_schema_confirm(200)
      end
    end

    context "認証失敗のとき" do
      context "Authorizationヘッダーがないとき" do
        it "401を返し、レスポンスがOpenAPIスキーマに一致する" do
          get "/api/v1/me/shared_group_users"

          expect(response).to have_http_status(:unauthorized)
          expect(response.media_type).to eq("application/problem+json")
          assert_response_schema_confirm(401)
        end
      end
    end
  end
end
