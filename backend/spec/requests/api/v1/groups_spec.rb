# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/groups", type: :request do
  subject(:do_request) { post "/api/v1/groups", params: params, headers: headers, as: :json }

  describe "認証" do
    context "Authorization が Bearer 形式で、verify! が成功するとき" do
      let(:token) { "dummy" }
      let(:headers) do
        {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        }
      end

      let(:allowed_origin) { ENV.fetch("CORS_ALLOWED_ORIGIN", "http://localhost:8000") }
      let(:sub) { "user_abc" }
      let(:payload) { { "sub" => sub, "azp" => allowed_origin } }

      let!(:user) { create(:user, external_uid: sub) }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).and_return(payload)
      end

      context "パラメータが正常なとき" do
        let(:params) do
          {
            group: {
              name: "旅行精算",
              currency: "JPY"
            }
          }
        end

        it "Group を作成し、作成者を OWNER として members に登録して 201 を返す" do
         expect { do_request }.to change(Group, :count).by(1).and change(Member, :count).by(1)


          expect(response).to have_http_status(:created)

          group = Group.order(:id).last
          expect(group.name).to eq("旅行精算")
          expect(group.currency).to eq("JPY")
          expect(group.public_id).to be_present
          expect(group.invite_token).to be_present

          member = Member.order(:id).last
          expect(member.group_id).to eq(group.id)
          expect(member.user_id).to eq(user.id)
          expect(member.role).to eq("OWNER")
          expect(member.active).to be(true)
          expect(member.joined_at).to be_present
          expect(member.left_at).to be_nil
        end
      end

      context "name が不正なとき（空文字）" do
        let(:params) do
          {
            group: {
              name: "",
              currency: "JPY"
            }
          }
        end

      it "422 を返し、Group / Member を作成しない" do
        expect { do_request }
          .to change(Group, :count).by(0)
          .and change(Member, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      end
    end

    context "Authorization ヘッダーが無いとき" do
      let(:headers) { { "Content-Type" => "application/json" } }
      let(:params) { { group: { name: "旅行精算" } } }

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

    context "Authorization が Bearer 形式で、verify! が失敗するとき" do
      let(:token) { "dummy" }
      let(:headers) do
        {
          "Authorization" => "Bearer #{token}",
          "Content-Type" => "application/json"
        }
      end
      let(:params) { { group: { name: "旅行精算" } } }

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
