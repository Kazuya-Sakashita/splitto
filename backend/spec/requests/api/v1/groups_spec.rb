# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/groups", type: :request do
  subject(:do_request) { post "/api/v1/groups", params: params, headers: headers, as: :json }

  describe "認証" do
    context "認証成功（Authorization: Bearer / verify! 成功）" do
      let!(:token) { "dummy" }
      let!(:headers) do
        {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        }
      end

      let!(:allowed_origin) { ENV.fetch("CORS_ALLOWED_ORIGIN", "http://localhost:8000") }
      let!(:sub) { "user_abc" }
      let!(:payload) { { "sub" => sub, "azp" => allowed_origin } }

      let!(:user) { create(:user, external_uid: sub) }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).and_return(payload)
      end

      context "パラメータが正常なとき" do
        let!(:params) { { group: { name: "旅行精算", currency: "JPY" } } }

        it "201 を返し、Group を作成し、作成者を OWNER として members に登録する" do
          expect { do_request }
            .to change(Group, :count).by(1)
            .and change(Member, :count).by(1)

          expect(response).to have_http_status(:created)

          created_group = Group.order(:id).last
          created_member = Member.order(:id).last

          expect(created_group.name).to eq("旅行精算")
          expect(created_group.currency).to eq("JPY")
          expect(created_group.public_id).to be_present
          expect(created_group.invite_token).to be_present

          expect(created_member.group_id).to eq(created_group.id)
          expect(created_member.user_id).to eq(user.id)
          expect(created_member.role).to eq("OWNER")
          expect(created_member.active).to be(true)
          expect(created_member.joined_at).to be_present
          expect(created_member.left_at).to be_nil

          body = response.parsed_body
          expect(body).to include("group")

          group_json = body.fetch("group")
          expect(group_json).to include(
            "public_id" => created_group.public_id,
            "name" => "旅行精算",
            "currency" => "JPY",
            "invite_token" => created_group.invite_token
          )
          expect(group_json["created_at"]).to be_a(String)
          expect(group_json["updated_at"]).to be_a(String)
        end
      end

      context "name が不正なとき（空文字）" do
        let!(:params) { { group: { name: "", currency: "JPY" } } }

        it "422 を返し、Group / Member を作成しない" do
          expect { do_request }
            .to change(Group, :count).by(0)
            .and change(Member, :count).by(0)

          expect(response).to have_http_status(:unprocessable_entity)

          body = response.parsed_body
          expect(body).to include("errors")
          expect(body["errors"]).to be_an(Array)
        end
      end
    end

    context "認証失敗（Authorization ヘッダーなし）" do
      let!(:headers) { { "Content-Type" => "application/json" } }
      let!(:params) { { group: { name: "旅行精算", currency: "JPY" } } }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!)
      end

      it "401 missing_token を返す" do
        do_request

        expect(response).to have_http_status(:unauthorized)
        expect(response.media_type).to eq("application/problem+json")
        expect(response.parsed_body).to include(
          "title" => "Unauthorized",
          "status" => 401,
          "reason" => "missing_token"
        )
      end

      it "Clerk::JwtVerifier.verify! を呼ばない" do
        do_request
        expect(Clerk::JwtVerifier).not_to have_received(:verify!)
      end
    end

    context "認証失敗（Authorization: Bearer / verify! 失敗）" do
      let!(:token) { "dummy" }
      let!(:headers) do
        {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        }
      end
      let!(:params) { { group: { name: "旅行精算", currency: "JPY" } } }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!)
          .and_raise(Clerk::JwtVerifier::VerificationError.new("decode failed"))
      end

      it "401 invalid_token を返す" do
        do_request

        expect(response).to have_http_status(:unauthorized)
        expect(response.media_type).to eq("application/problem+json")
        expect(response.parsed_body).to include(
          "title" => "Unauthorized",
          "status" => 401,
          "reason" => "invalid_token"
        )
      end
    end
  end
end
