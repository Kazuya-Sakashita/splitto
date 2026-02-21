# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/me", type: :request do
  subject(:do_request) { get "/api/v1/me", headers: headers }

  describe "認証" do
    describe "正常系" do
      context "Authorization が Bearer 形式で、verify! が成功するとき" do
        let!(:token) { "dummy" }
        let!(:headers) { { "Authorization" => "Bearer #{token}" } }

        let!(:allowed_origin) { ENV.fetch("CORS_ALLOWED_ORIGIN", "http://localhost:8000") }
        let!(:payload) { { "sub" => sub, "azp" => allowed_origin } }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!).and_return(payload)
        end

        context "User がまだ存在しないとき" do
          let!(:sub) { "user_abc" }

          it "User を作成し 200 を返し、OpenAPI schema に一致する" do
            expect { do_request }.to change(User, :count).by(1)

            aggregate_failures do
              expect(response).to have_http_status(:ok)
              expect(User.find_by(external_uid: sub)).to be_present
              assert_response_schema_confirm(200)
            end
          end
        end

        context "同じ sub の User が既に存在するとき" do
          let!(:sub) { "user_same" }
          let!(:existing_user) { create(:user, external_uid: sub) }

          it "重複作成せず 200 を返し、OpenAPI schema に一致する" do
            expect { do_request }.not_to change(User, :count)

            aggregate_failures do
              expect(response).to have_http_status(:ok)
              expect(User.where(external_uid: sub).count).to eq(1)
              expect(User.find_by!(external_uid: sub).id).to eq(existing_user.id)
              assert_response_schema_confirm(200)
            end
          end
        end
      end
    end

    describe "異常系" do
      context "Authorization ヘッダーが無いとき" do
        let!(:headers) { {} }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!)
        end

        it "401 missing_token を返す（Problem Details）" do
          do_request

          aggregate_failures do
            expect(response).to have_http_status(:unauthorized)
            expect(response.media_type).to eq("application/problem+json")
            assert_response_schema_confirm(401)

            expect(response.parsed_body).to include(
              "title" => "Unauthorized",
              "status" => 401,
              "reason" => "missing_token",
              "detail" => "Authorization header is missing or invalid"
            )
          end
        end

        it "Clerk::JwtVerifier.verify! を呼ばない" do
          do_request
          expect(Clerk::JwtVerifier).not_to have_received(:verify!)
        end
      end

      context "Authorization が Bearer 形式でないとき" do
        let!(:headers) { { "Authorization" => "Token abc" } }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!)
        end

        it "401 missing_token を返す（Problem Details）" do
          do_request

          aggregate_failures do
            expect(response).to have_http_status(:unauthorized)
            expect(response.media_type).to eq("application/problem+json")
            assert_response_schema_confirm(401)

            expect(response.parsed_body).to include(
              "title" => "Unauthorized",
              "status" => 401,
              "reason" => "missing_token",
              "detail" => "Authorization header is missing or invalid"
            )
          end
        end

        it "Clerk::JwtVerifier.verify! を呼ばない" do
          do_request
          expect(Clerk::JwtVerifier).not_to have_received(:verify!)
        end
      end

      context "Authorization が Bearer 形式で、verify! が失敗するとき" do
        let!(:token) { "dummy" }
        let!(:headers) { { "Authorization" => "Bearer #{token}" } }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!)
            .and_raise(Clerk::JwtVerifier::VerificationError.new("decode failed"))
        end

        it "401 invalid_token を返す（Problem Details）" do
          do_request

          aggregate_failures do
            expect(response).to have_http_status(:unauthorized)
            expect(response.media_type).to eq("application/problem+json")
            assert_response_schema_confirm(401)

            expect(response.parsed_body).to include(
              "title" => "Unauthorized",
              "status" => 401,
              "reason" => "invalid_token",
              "detail" => "Token verification failed"
            )
          end
        end
      end

      context "Authorization が Bearer 形式で、azp 不一致などで verify! が失敗するとき" do
        let!(:token) { "dummy" }
        let!(:headers) { { "Authorization" => "Bearer #{token}" } }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!)
            .and_raise(Clerk::JwtVerifier::VerificationError.new("invalid azp"))
        end

        it "401 invalid_token を返す（Problem Details）" do
          do_request

          aggregate_failures do
            expect(response).to have_http_status(:unauthorized)
            expect(response.media_type).to eq("application/problem+json")
            assert_response_schema_confirm(401)

            expect(response.parsed_body).to include(
              "title" => "Unauthorized",
              "status" => 401,
              "reason" => "invalid_token",
              "detail" => "Token verification failed"
            )
          end
        end
      end
    end
  end
end
