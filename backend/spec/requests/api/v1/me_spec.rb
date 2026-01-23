# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/me", type: :request do
  subject(:do_request) { get path, headers: headers }

  let(:path) { "/api/v1/me" }
  let(:headers) { {} }
  let(:token) { "dummy" }

  let(:payload) { { "sub" => sub, "azp" => azp } }
  let(:sub) { "default_sub" }
  let(:azp) { "http://localhost:8000" }

  describe "認証" do
    context "Authorization ヘッダーが無いとき" do
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
        allow(Clerk::JwtVerifier).to receive(:verify!)

        do_request

        expect(Clerk::JwtVerifier).not_to have_received(:verify!)
      end
    end

    context "Authorization が Bearer 形式でないとき" do
      let(:headers) { { "Authorization" => "Token abc" } }

      it "401 missing_token を返す" do
        do_request

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body).to include("reason" => "missing_token")
      end

      it "Clerk::JwtVerifier.verify! を呼ばない" do
        allow(Clerk::JwtVerifier).to receive(:verify!)

        do_request

        expect(Clerk::JwtVerifier).not_to have_received(:verify!)
      end
    end

    context "Authorization が Bearer 形式のとき" do
      let(:headers) { { "Authorization" => "Bearer #{token}" } }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).and_return(payload)
      end

      context "verify! が失敗するとき" do
        before do
          allow(Clerk::JwtVerifier).to receive(:verify!)
            .and_raise(Clerk::JwtVerifier::VerificationError.new("decode failed"))
        end

        it "401 invalid_token を返す" do
          do_request

          expect(response).to have_http_status(:unauthorized)
          expect(response.parsed_body).to include("reason" => "invalid_token")
        end
      end

      context "azp 不一致などで verify! が失敗するとき" do
        before do
          allow(Clerk::JwtVerifier).to receive(:verify!)
            .and_raise(Clerk::JwtVerifier::VerificationError.new("invalid azp"))
        end

        it "401 invalid_token を返す" do
          do_request

          expect(response).to have_http_status(:unauthorized)
          expect(response.parsed_body).to include("reason" => "invalid_token")
        end
      end

      context "verify! が成功するとき" do
        context "User がまだ存在しないとき" do
          let(:sub) { "user_abc" }

          it "User を作成し 200 を返す" do
            expect { do_request }.to change(User, :count).by(1)

            expect(response).to have_http_status(:ok)
            expect(User.find_by(external_uid: sub)).to be_present
          end
        end

        context "同じ sub の User が既に存在するとき" do
          let(:sub) { "user_same" }

          # ここは「事前に必ず存在していてほしい」ので let! が自然
          let!(:existing_user) { User.create!(external_uid: sub) }

          it "重複作成せず 200 を返す" do
            expect { do_request }.not_to change(User, :count)

            expect(response).to have_http_status(:ok)
            expect(User.where(external_uid: sub).count).to eq(1)
            expect(User.find_by!(external_uid: sub).id).to eq(existing_user.id)
          end
        end
      end
    end
  end
end
