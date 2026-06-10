# backend/spec/requests/api/v1/groups/expenses/create_spec.rb
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/groups/:group_id/expenses", type: :request do
  subject(:create_request) do
    post "/api/v1/groups/#{group_id_param}/expenses",
         params: body.to_json,
         headers: headers
  end

  let!(:group)        { create(:group) }
  let!(:owner_user)   { create(:user, external_uid: "clerk_owner_123") }
  let!(:member_user)  { create(:user, external_uid: "clerk_member_123") }
  let!(:token)        { "test-token" }
  let!(:headers) do
    {
      "Authorization" => "Bearer #{token}",
      "Content-Type" => "application/json"
    }
  end
  let!(:group_id_param) { group.public_id }

  let!(:owner_member) do
    create(:member, group: group, user: owner_user, role: "OWNER", active: true, joined_at: Time.current)
  end
  let!(:self_member) do
    create(:member, group: group, user: member_user, role: "MEMBER", active: true, joined_at: Time.current)
  end

  let!(:body) do
    {
      paid_by_id: owner_user.public_id,
      created_by_id: owner_user.public_id,
      amount_cents: 1000,
      paid_on: "2026-06-10",
      split_type: "EQUAL_ALL",
      splits: [
        { user_id: owner_user.public_id, share_cents: 500 },
        { user_id: member_user.public_id, share_cents: 500 }
      ]
    }
  end

  context "認証に成功しているとき" do
    context "実行ユーザーが active member で、正常なリクエストを送ったとき" do
      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => owner_user.external_uid }
        )
      end

      it "201 Created を返す" do
        create_request
        expect(response).to have_http_status(:created)
      end

      it "Expense が 1 件作成される" do
        expect { create_request }.to change { Expense.count }.by(1)
      end

      it "Split が splits.size 件作成される" do
        expect { create_request }.to change { Split.count }.by(2)
      end

      it "レスポンスに expense / splits / attachments が含まれる" do
        create_request

        body = response.parsed_body
        expect(body).to include("expense", "splits", "attachments")
        expect(body["expense"]).to include(
          "group_id" => group.public_id,
          "paid_by_id" => owner_user.public_id,
          "created_by_id" => owner_user.public_id,
          "amount_cents" => 1000,
          "paid_on" => "2026-06-10",
          "split_type" => "EQUAL_ALL"
        )
        expect(body["splits"].size).to eq(2)
        expect(body["attachments"]).to eq([])
      end

      it "201 の OpenAPI スキーマに一致する" do
        create_request
        assert_response_schema_confirm(201)
      end
    end

    context "実行ユーザーが代理で他メンバーを payer に指定したとき" do
      let!(:body) do
        {
          paid_by_id: member_user.public_id,
          created_by_id: owner_user.public_id,
          amount_cents: 1000,
          paid_on: "2026-06-10",
          split_type: "EQUAL_ALL",
          splits: [
            { user_id: owner_user.public_id, share_cents: 500 },
            { user_id: member_user.public_id, share_cents: 500 }
          ]
        }
      end

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => owner_user.external_uid }
        )
      end

      it "201 を返す（代理入力が許容される）" do
        create_request
        expect(response).to have_http_status(:created)
      end

      it "created_by は実行ユーザーで上書きされる" do
        create_request
        expect(response.parsed_body["expense"]["created_by_id"]).to eq(owner_user.public_id)
      end

      it "201 の OpenAPI スキーマに一致する" do
        create_request
        assert_response_schema_confirm(201)
      end
    end

    context "splits の合計が amount_cents と一致しないとき" do
      let!(:body) do
        {
          paid_by_id: owner_user.public_id,
          created_by_id: owner_user.public_id,
          amount_cents: 1000,
          paid_on: "2026-06-10",
          split_type: "EQUAL_ALL",
          splits: [
            { user_id: owner_user.public_id, share_cents: 400 },
            { user_id: member_user.public_id, share_cents: 500 }
          ]
        }
      end

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => owner_user.external_uid }
        )
      end

      it "422 を返す" do
        create_request
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "Expense は作成されない" do
        expect { create_request }.not_to change { Expense.count }
      end

      it "422 の OpenAPI スキーマに一致する" do
        create_request
        assert_response_schema_confirm(422)
      end
    end

    context "paid_by_id に存在しない user_id を指定したとき" do
      let!(:body) do
        {
          paid_by_id: "usr_not_found",
          created_by_id: owner_user.public_id,
          amount_cents: 1000,
          paid_on: "2026-06-10",
          split_type: "EQUAL_ALL",
          splits: [
            { user_id: owner_user.public_id, share_cents: 1000 }
          ]
        }
      end

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => owner_user.external_uid }
        )
      end

      it "422 を返す" do
        create_request
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "reason に invalid_payer を返す" do
        create_request
        expect(response.parsed_body["reason"]).to eq("invalid_payer")
      end

      it "422 の OpenAPI スキーマに一致する" do
        create_request
        assert_response_schema_confirm(422)
      end
    end

    context "splits にグループ外ユーザーが含まれるとき" do
      let!(:outsider) { create(:user) }
      let!(:body) do
        {
          paid_by_id: owner_user.public_id,
          created_by_id: owner_user.public_id,
          amount_cents: 1000,
          paid_on: "2026-06-10",
          split_type: "EQUAL_ALL",
          splits: [
            { user_id: owner_user.public_id, share_cents: 500 },
            { user_id: outsider.public_id, share_cents: 500 }
          ]
        }
      end

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => owner_user.external_uid }
        )
      end

      it "422 を返す" do
        create_request
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "reason に invalid_split_member を返す" do
        create_request
        expect(response.parsed_body["reason"]).to eq("invalid_split_member")
      end

      it "Expense は作成されない" do
        expect { create_request }.not_to change { Expense.count }
      end
    end

    context "実行ユーザーがグループメンバーではないとき" do
      let!(:outsider) { create(:user, external_uid: "clerk_outsider_123") }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => outsider.external_uid }
        )
      end

      it "403 を返す" do
        create_request
        expect(response).to have_http_status(:forbidden)
      end

      it "reason に not_group_member を返す" do
        create_request
        expect(response.parsed_body["reason"]).to eq("not_group_member")
      end

      it "403 の OpenAPI スキーマに一致する" do
        create_request
        assert_response_schema_confirm(403)
      end
    end

    context "対象グループが存在しないとき" do
      let!(:group_id_param) { "grp_not_found" }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
          { "sub" => owner_user.external_uid }
        )
      end

      it "404 を返す" do
        create_request
        expect(response).to have_http_status(:not_found)
      end

      it "reason に group_not_found を返す" do
        create_request
        expect(response.parsed_body["reason"]).to eq("group_not_found")
      end

      it "404 の OpenAPI スキーマに一致する" do
        create_request
        assert_response_schema_confirm(404)
      end
    end
  end

  context "認証に失敗しているとき" do
    context "Authorization ヘッダーがないとき" do
      let!(:group_id_param) { "grp_unused" }
      let!(:headers) do
        { "Content-Type" => "application/json" }
      end

      it "401 を返す" do
        create_request
        expect(response).to have_http_status(:unauthorized)
      end

      it "reason に missing_token を返す" do
        create_request
        expect(response.parsed_body["reason"]).to eq("missing_token")
      end

      it "401 の OpenAPI スキーマに一致する" do
        create_request
        assert_response_schema_confirm(401)
      end
    end
  end
end
