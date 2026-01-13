# spec/requests/api/v1/me_spec.rb
require "rails_helper"

RSpec.describe "GET /api/v1/me", type: :request do
  let(:path) { "/api/v1/me" }

  before do
    # 403対策（HostAuthorization）
    host! "localhost"

    # ✅ 基本は verify! をスタブして外部依存（JWT decode / JWKS fetch）を排除する
    # 必要なテストだけ個別に上書きする
    allow(Clerk::JwtVerifier).to receive(:verify!).and_return(
      { "sub" => "default_sub", "azp" => "http://localhost:8000" }
    )
  end

  def stub_verify!(payload:)
    allow(Clerk::JwtVerifier).to receive(:verify!).and_return(payload)
  end

  def with_env(key, value)
    original = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = original
  end

  it "Authorization が無いと 401 missing_token" do
    get path
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to include("reason" => "missing_token")
  end

  it "Bearer 形式でないと 401 missing_token" do
    get path, headers: { "Authorization" => "Token abc" }
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to include("reason" => "missing_token")
  end

  it "verify! が失敗すると 401 invalid_token" do
    allow(Clerk::JwtVerifier).to receive(:verify!)
      .and_raise(Clerk::JwtVerifier::VerificationError.new("bad token"))

    get path, headers: { "Authorization" => "Bearer dummy" }

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).to include("reason" => "invalid_token")
  end

  it "azp が許可リストに無いと 401 invalid_azp" do
    with_env("CLERK_AUTHORIZED_PARTIES", "http://localhost:8000") do
      stub_verify!(payload: { "sub" => "user_123", "azp" => "http://localhost:9999" })

      get path, headers: { "Authorization" => "Bearer dummy" }

      expect(response).to have_http_status(:unauthorized)
      body = response.parsed_body
      expect(body).to include("reason" => "invalid_azp")
      expect(body["azp"]).to eq("http://localhost:9999")
    end
  end

  it "認証成功で user を作成/取得できる" do
    with_env("CLERK_AUTHORIZED_PARTIES", "") do
      stub_verify!(payload: { "sub" => "user_abc", "azp" => "http://localhost:8000" })

      expect { get path, headers: { "Authorization" => "Bearer dummy" } }
        .to change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(User.find_by(external_uid: "user_abc")).to be_present
    end
  end

  it "同じ sub で2回呼ぶと user は増えない（重複作成しない）" do
    with_env("CLERK_AUTHORIZED_PARTIES", "") do
      stub_verify!(payload: { "sub" => "user_same", "azp" => "http://localhost:8000" })

      expect { get path, headers: { "Authorization" => "Bearer dummy" } }
        .to change(User, :count).by(1)

      created_user = User.find_by!(external_uid: "user_same")

      expect { get path, headers: { "Authorization" => "Bearer dummy" } }
        .not_to change(User, :count)

      expect(User.where(external_uid: "user_same").count).to eq(1)
      expect(User.find_by!(external_uid: "user_same").id).to eq(created_user.id)
    end
  end
end
