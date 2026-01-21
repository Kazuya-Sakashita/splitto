# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/me", type: :request do
  let(:path) { "/api/v1/me" }
  let(:headers) { { "Authorization" => "Bearer dummy" } }

  # ✅ デフォルトは verify! を成功扱いにして外部依存（JWT decode / JWKS fetch）を排除
  #    失敗ケースだけ各 example で上書きする
  before do
    allow(Clerk::JwtVerifier).to receive(:verify!).and_return(
      { "sub" => "default_sub", "azp" => "http://localhost:8000" }
    )
  end

  def stub_verify!(payload:)
    allow(Clerk::JwtVerifier).to receive(:verify!).and_return(payload)
  end

  def stub_verify_error!(message: "bad token")
    allow(Clerk::JwtVerifier).to receive(:verify!)
      .and_raise(Clerk::JwtVerifier::VerificationError.new(message))
  end

  it "Authorization が無いと 401 missing_token" do
    get path

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to include(
      "error" => "Unauthorized",
      "reason" => "missing_token"
    )
  end

  it "Bearer 形式でないと 401 missing_token" do
    get path, headers: { "Authorization" => "Token abc" }

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to include("reason" => "missing_token")
  end

  it "verify! が失敗すると 401 invalid_token" do
    stub_verify_error!(message: "decode failed")

    get path, headers: headers

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to include("reason" => "invalid_token")
  end

  it "azp 不一致などで verify! が失敗すると 401 invalid_token" do
    # ✅ azp チェックは JwtVerifier 側の責務（invalid azp でも verify! は例外になる）
    stub_verify_error!(message: "invalid azp")

    get path, headers: headers

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to include("reason" => "invalid_token")
  end

  it "認証成功で user を作成/取得できる" do
    stub_verify!(payload: { "sub" => "user_abc", "azp" => "http://localhost:8000" })

    expect { get path, headers: headers }
      .to change(User, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(User.find_by(external_uid: "user_abc")).to be_present
  end

  it "同じ sub で2回呼ぶと user は増えない（重複作成しない）" do
    stub_verify!(payload: { "sub" => "user_same", "azp" => "http://localhost:8000" })

    expect { get path, headers: headers }
      .to change(User, :count).by(1)

    created_user = User.find_by!(external_uid: "user_same")

    expect { get path, headers: headers }
      .not_to change(User, :count)

    expect(User.where(external_uid: "user_same").count).to eq(1)
    expect(User.find_by!(external_uid: "user_same").id).to eq(created_user.id)
  end
end
