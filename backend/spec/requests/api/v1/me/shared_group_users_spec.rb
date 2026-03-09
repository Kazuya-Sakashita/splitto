# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/me/shared_group_users", type: :request do
  describe "GET /api/v1/me/shared_group_users" do
    context "認証成功のとき" do
      let!(:external_uid) { "clerk_user_123" }
      let!(:token) { "test-token" }
      let!(:headers) { { "Authorization" => "Bearer #{token}" } }
      let!(:user) { create(:user, external_uid: external_uid) }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => external_uid }
        )
      end

      context "同じグループに所属したユーザーがいるとき" do
        let!(:group) { create(:group) }
        let!(:other_group) { create(:group) }
        let!(:other_user) { create(:user) }
        let!(:unrelated_user) { create(:user) }

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

        let!(:unrelated_member) do
          create(
            :member,
            user: unrelated_user,
            group: other_group,
            updated_at: Time.zone.parse("2026-03-06 10:00:00")
          )
        end

        it "同じグループに所属したユーザーが取得できる" do
          get "/api/v1/me/shared_group_users", headers: headers

          expect(response).to have_http_status(:ok)
          assert_response_schema_confirm(200)

          body = JSON.parse(response.body)

          expect(body["shared_group_users"]).to eq(
            [
              {
                "user_id" => other_user.public_id,
                "last_together_at" => other_member.updated_at.iso8601
              }
            ]
          )
        end
      end

      context "同じグループに所属した他ユーザーがいないとき" do
        let!(:group) { create(:group) }

        let!(:my_member) do
          create(
            :member,
            user: user,
            group: group,
            updated_at: Time.zone.parse("2026-03-05 10:00:00")
          )
        end

        it "空配列が返る" do
          get "/api/v1/me/shared_group_users", headers: headers

          expect(response).to have_http_status(:ok)
          assert_response_schema_confirm(200)

          body = JSON.parse(response.body)

          expect(body["shared_group_users"]).to eq([])
        end
      end

      context "自分自身を除外するとき" do
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

        it "自分自身は含まれない" do
          get "/api/v1/me/shared_group_users", headers: headers

          expect(response).to have_http_status(:ok)
          assert_response_schema_confirm(200)

          body = JSON.parse(response.body)
          user_ids = body["shared_group_users"].map { |shared_group_user| shared_group_user["user_id"] }

          expect(user_ids).not_to include(user.public_id)
        end
      end
    end

    context "認証失敗のとき" do
      context "Authorizationヘッダーがないとき" do
        it "401を返す" do
          get "/api/v1/me/shared_group_users"

          expect(response).to have_http_status(:unauthorized)
          assert_response_schema_confirm(401)
        end
      end
    end
  end
end
