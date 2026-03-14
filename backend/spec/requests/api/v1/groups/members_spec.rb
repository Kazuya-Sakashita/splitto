# backend/spec/requests/api/v1/groups/members_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/groups/:group_id/members", type: :request do
  describe "POST /api/v1/groups/:group_id/members" do
    let!(:group) { create(:group) }
    let!(:owner) { create(:user, external_uid: "clerk_owner_123") }
    let!(:target_user) { create(:user) }
    let!(:token) { "test-token" }
    let!(:headers) do
      {
        "Authorization" => "Bearer #{token}",
        "Content-Type" => "application/json"
      }
    end
    let!(:params) do
      {
        user_id: target_user.public_id
      }
    end

    before do
      create(
        :member,
        group: group,
        user: owner,
        role: "OWNER",
        active: true,
        joined_at: Time.current
      )

      allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
        { "sub" => owner.external_uid }
      )
    end

    context "認証に成功しているとき" do
      context "実行ユーザーがグループのOWNERのとき" do
        context "追加対象ユーザーが存在するとき" do
          it "201 Created を返す" do
            post "/api/v1/groups/#{group.public_id}/members",
                 params: params.to_json,
                 headers: headers

            expect(response).to have_http_status(:created)
          end

          it "メンバーを追加できる" do
            expect do
              post "/api/v1/groups/#{group.public_id}/members",
                   params: params.to_json,
                   headers: headers
            end.to change(Member, :count).by(1)
          end

          it "追加したメンバーを返す" do
            post "/api/v1/groups/#{group.public_id}/members",
                 params: params.to_json,
                 headers: headers

            body = response.parsed_body

            expect(body["member"]).to include(
              "group_id" => group.public_id,
              "user_id" => target_user.public_id,
              "role" => "MEMBER",
              "active" => true
            )
            expect(body["member"]["id"]).to be_present
            expect(body["member"]["joined_at"]).to be_present
            expect(body["member"]["created_at"]).to be_present
            expect(body["member"]["updated_at"]).to be_present
          end

          it "201 の OpenAPI スキーマに一致する" do
            post "/api/v1/groups/#{group.public_id}/members",
                 params: params.to_json,
                 headers: headers

            assert_response_schema_confirm(201)
          end
        end

        context "追加対象ユーザーが存在しないとき" do
          let!(:params) do
            {
              user_id: "usr_not_found"
            }
          end

          it "404 Not Found を返す" do
            post "/api/v1/groups/#{group.public_id}/members",
                 params: params.to_json,
                 headers: headers

            expect(response).to have_http_status(:not_found)
          end

          it "reason に user_not_found を返す" do
            post "/api/v1/groups/#{group.public_id}/members",
                 params: params.to_json,
                 headers: headers

            expect(response.parsed_body["reason"]).to eq("user_not_found")
          end

          it "404 の OpenAPI スキーマに一致する" do
            post "/api/v1/groups/#{group.public_id}/members",
                 params: params.to_json,
                 headers: headers

            assert_response_schema_confirm(404)
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

          it "409 Conflict を返す" do
            post "/api/v1/groups/#{group.public_id}/members",
                 params: params.to_json,
                 headers: headers

            expect(response).to have_http_status(:conflict)
          end

          it "reason に member_already_exists を返す" do
            post "/api/v1/groups/#{group.public_id}/members",
                 params: params.to_json,
                 headers: headers

            expect(response.parsed_body["reason"]).to eq("member_already_exists")
          end

          it "メンバー数が増えない" do
            expect do
              post "/api/v1/groups/#{group.public_id}/members",
                   params: params.to_json,
                   headers: headers
            end.not_to change(Member, :count)
          end

          it "409 の OpenAPI スキーマに一致する" do
            post "/api/v1/groups/#{group.public_id}/members",
                 params: params.to_json,
                 headers: headers

            assert_response_schema_confirm(409)
          end
        end
      end

      context "実行ユーザーがグループのOWNERではないとき" do
        let!(:member_user) { create(:user, external_uid: "clerk_member_123") }

        before do
          Member.find_by!(group: group, user: owner).destroy!

          create(
            :member,
            group: group,
            user: member_user,
            role: "MEMBER",
            active: true,
            joined_at: Time.current
          )

          allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
            { "sub" => member_user.external_uid }
          )
        end

        it "403 Forbidden を返す" do
          post "/api/v1/groups/#{group.public_id}/members",
               params: params.to_json,
               headers: headers

          expect(response).to have_http_status(:forbidden)
        end

        it "reason に insufficient_role を返す" do
          post "/api/v1/groups/#{group.public_id}/members",
               params: params.to_json,
               headers: headers

          expect(response.parsed_body["reason"]).to eq("insufficient_role")
        end

        it "メンバー数が増えない" do
          expect do
            post "/api/v1/groups/#{group.public_id}/members",
                 params: params.to_json,
                 headers: headers
          end.not_to change(Member, :count)
        end

        it "403 の OpenAPI スキーマに一致する" do
          post "/api/v1/groups/#{group.public_id}/members",
               params: params.to_json,
               headers: headers

          assert_response_schema_confirm(403)
        end
      end

      context "実行ユーザーがグループメンバーではないとき" do
        let!(:other_user) { create(:user, external_uid: "clerk_other_123") }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
            { "sub" => other_user.external_uid }
          )
        end

        it "403 Forbidden を返す" do
          post "/api/v1/groups/#{group.public_id}/members",
               params: params.to_json,
               headers: headers

          expect(response).to have_http_status(:forbidden)
        end

        it "reason に not_group_member を返す" do
          post "/api/v1/groups/#{group.public_id}/members",
               params: params.to_json,
               headers: headers

          expect(response.parsed_body["reason"]).to eq("not_group_member")
        end

        it "403 の OpenAPI スキーマに一致する" do
          post "/api/v1/groups/#{group.public_id}/members",
               params: params.to_json,
               headers: headers

          assert_response_schema_confirm(403)
        end
      end

      context "対象グループが存在しないとき" do
        it "404 Not Found を返す" do
          post "/api/v1/groups/grp_not_found/members",
               params: params.to_json,
               headers: headers

          expect(response).to have_http_status(:not_found)
        end

        it "reason に group_not_found を返す" do
          post "/api/v1/groups/grp_not_found/members",
               params: params.to_json,
               headers: headers

          expect(response.parsed_body["reason"]).to eq("group_not_found")
        end

        it "404 の OpenAPI スキーマに一致する" do
          post "/api/v1/groups/grp_not_found/members",
               params: params.to_json,
               headers: headers

          assert_response_schema_confirm(404)
        end
      end
    end

    context "認証に失敗しているとき" do
      let!(:headers) do
        {
          "Content-Type" => "application/json"
        }
      end

      it "401 Unauthorized を返す" do
        post "/api/v1/groups/#{group.public_id}/members",
             params: params.to_json,
             headers: headers

        expect(response).to have_http_status(:unauthorized)
      end

      it "reason に missing_token を返す" do
        post "/api/v1/groups/#{group.public_id}/members",
             params: params.to_json,
             headers: headers

        expect(response.parsed_body["reason"]).to eq("missing_token")
      end

      it "401 の OpenAPI スキーマに一致する" do
        post "/api/v1/groups/#{group.public_id}/members",
             params: params.to_json,
             headers: headers

        assert_response_schema_confirm(401)
      end
    end
  end
end
