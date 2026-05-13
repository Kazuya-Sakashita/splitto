# backend/spec/requests/api/v1/groups/members/leave_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/groups/:group_id/members/:id/leave", type: :request do
  subject(:leave_request) do
    post "/api/v1/groups/#{group_id_param}/members/#{member_id_param}/leave",
         headers: headers
  end

  let!(:group) { create(:group) }
  let!(:token) { "test-token" }
  let!(:headers) do
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end
  let!(:group_id_param)  { group.public_id }
  let!(:member_id_param) { "mem_dummy" }

  context "認証に成功しているとき" do
    let!(:owner_user)  { create(:user, external_uid: "clerk_owner_123") }
    let!(:member_user) { create(:user, external_uid: "clerk_member_123") }

    before do
      allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
        { "sub" => member_user.external_uid }
      )
    end

    context "MEMBER 自身が active のとき" do
      let!(:self_member) do
        create(
          :member,
          group: group,
          user: member_user,
          role: "MEMBER",
          active: true,
          joined_at: Time.current
        )
      end
      let!(:member_id_param) { self_member.public_id }

      it "200 OK を返す" do
        leave_request
        expect(response).to have_http_status(:ok)
      end

      it "メンバーが active=false になる" do
        expect { leave_request }
          .to change { self_member.reload.active }.from(true).to(false)
      end

      it "left_at が記録される" do
        expect { leave_request }
          .to change { self_member.reload.left_at }.from(nil)
      end

      it "退出後のメンバー情報を返す" do
        leave_request

        body = response.parsed_body
        expect(body["member"]).to include(
          "id" => self_member.public_id,
          "group_id" => group.public_id,
          "user_id" => member_user.public_id,
          "role" => "MEMBER",
          "active" => false
        )
        expect(body["member"]["left_at"]).to be_present
      end

      it "200 の OpenAPI スキーマに一致する" do
        leave_request
        assert_response_schema_confirm(200)
      end
    end

    context "すでに inactive なメンバーのとき" do
      let!(:previous_left_at) { 1.day.ago }
      let!(:self_member) do
        create(
          :member,
          group: group,
          user: member_user,
          role: "MEMBER",
          active: false,
          joined_at: 2.days.ago,
          left_at: previous_left_at
        )
      end
      let!(:member_id_param) { self_member.public_id }

      it "200 OK を返す（冪等）" do
        leave_request
        expect(response).to have_http_status(:ok)
      end

      it "active が変わらない" do
        expect { leave_request }.not_to change { self_member.reload.active }
      end

      it "left_at が変わらない" do
        expect { leave_request }.not_to change { self_member.reload.left_at }
      end

      it "200 の OpenAPI スキーマに一致する" do
        leave_request
        assert_response_schema_confirm(200)
      end
    end

    context "OWNER 自身が退出しようとしたとき" do
      let!(:owner_member) do
        create(
          :member,
          group: group,
          user: owner_user,
          role: "OWNER",
          active: true,
          joined_at: Time.current
        )
      end
      let!(:member_id_param) { owner_member.public_id }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => owner_user.external_uid }
        )
      end

      it "422 Unprocessable Entity を返す" do
        leave_request
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "reason に owner_cannot_leave を返す" do
        leave_request
        expect(response.parsed_body["reason"]).to eq("owner_cannot_leave")
      end

      it "メンバーの active が変わらない" do
        expect { leave_request }.not_to change { owner_member.reload.active }
      end

      it "422 の OpenAPI スキーマに一致する" do
        leave_request
        assert_response_schema_confirm(422)
      end
    end

    context "他人の memberId を退出しようとしたとき" do
      let!(:owner_member) do
        create(
          :member,
          group: group,
          user: owner_user,
          role: "OWNER",
          active: true,
          joined_at: Time.current
        )
      end
      let!(:self_member) do
        create(
          :member,
          group: group,
          user: member_user,
          role: "MEMBER",
          active: true,
          joined_at: Time.current
        )
      end
      let!(:member_id_param) { owner_member.public_id }

      it "403 Forbidden を返す" do
        leave_request
        expect(response).to have_http_status(:forbidden)
      end

      it "reason に cannot_leave_other_member を返す" do
        leave_request
        expect(response.parsed_body["reason"]).to eq("cannot_leave_other_member")
      end

      it "対象メンバーの active が変わらない" do
        expect { leave_request }.not_to change { owner_member.reload.active }
      end

      it "403 の OpenAPI スキーマに一致する" do
        leave_request
        assert_response_schema_confirm(403)
      end
    end

    context "inactive な自分の member を持つユーザーが他人を退出させようとしたとき" do
      let!(:owner_member) do
        create(
          :member,
          group: group,
          user: owner_user,
          role: "OWNER",
          active: true,
          joined_at: Time.current
        )
      end
      let!(:self_member) do
        create(
          :member,
          group: group,
          user: member_user,
          role: "MEMBER",
          active: false,
          joined_at: 2.days.ago,
          left_at: 1.day.ago
        )
      end
      let!(:member_id_param) { owner_member.public_id }

      it "403 Forbidden を返す" do
        leave_request
        expect(response).to have_http_status(:forbidden)
      end

      it "reason に cannot_leave_other_member を返す" do
        leave_request
        expect(response.parsed_body["reason"]).to eq("cannot_leave_other_member")
      end

      it "対象メンバーの active が変わらない" do
        expect { leave_request }.not_to change { owner_member.reload.active }
      end

      it "403 の OpenAPI スキーマに一致する" do
        leave_request
        assert_response_schema_confirm(403)
      end
    end

    context "実行ユーザーがグループメンバーではないとき" do
      let!(:outsider) { create(:user, external_uid: "clerk_outsider_123") }
      let!(:self_member) do
        create(
          :member,
          group: group,
          user: member_user,
          role: "MEMBER",
          active: true,
          joined_at: Time.current
        )
      end
      let!(:member_id_param) { self_member.public_id }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => outsider.external_uid }
        )
      end

      it "403 Forbidden を返す" do
        leave_request
        expect(response).to have_http_status(:forbidden)
      end

      it "reason に not_group_member を返す" do
        leave_request
        expect(response.parsed_body["reason"]).to eq("not_group_member")
      end

      it "403 の OpenAPI スキーマに一致する" do
        leave_request
        assert_response_schema_confirm(403)
      end
    end

    context "対象グループが存在しないとき" do
      let!(:group_id_param)  { "grp_not_found" }
      let!(:member_id_param) { "mem_dummy" }

      it "404 Not Found を返す" do
        leave_request
        expect(response).to have_http_status(:not_found)
      end

      it "reason に group_not_found を返す" do
        leave_request
        expect(response.parsed_body["reason"]).to eq("group_not_found")
      end

      it "404 の OpenAPI スキーマに一致する" do
        leave_request
        assert_response_schema_confirm(404)
      end
    end

    context "対象メンバーが存在しないとき" do
      let!(:self_member) do
        create(
          :member,
          group: group,
          user: member_user,
          role: "MEMBER",
          active: true,
          joined_at: Time.current
        )
      end
      let!(:member_id_param) { "mem_not_found" }

      it "404 Not Found を返す" do
        leave_request
        expect(response).to have_http_status(:not_found)
      end

      it "reason に member_not_found を返す" do
        leave_request
        expect(response.parsed_body["reason"]).to eq("member_not_found")
      end

      it "404 の OpenAPI スキーマに一致する" do
        leave_request
        assert_response_schema_confirm(404)
      end
    end
  end

  context "認証に失敗しているとき" do
    context "Authorization ヘッダーがないとき" do
      let!(:group_id_param)  { "grp_unused" }
      let!(:member_id_param) { "mem_unused" }
      let!(:headers) do
        {
          "Content-Type" => "application/json"
        }
      end

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!)
      end

      it "401 Unauthorized を返す" do
        leave_request
        expect(response).to have_http_status(:unauthorized)
      end

      it "reason に missing_token を返す" do
        leave_request
        expect(response.parsed_body["reason"]).to eq("missing_token")
      end

      it "Content-Type が application/problem+json になる" do
        leave_request
        expect(response.media_type).to eq("application/problem+json")
      end

      it "401 の OpenAPI スキーマに一致する" do
        leave_request
        assert_response_schema_confirm(401)
      end
    end
  end
end
