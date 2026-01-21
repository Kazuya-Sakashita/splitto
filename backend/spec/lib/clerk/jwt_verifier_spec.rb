# spec/lib/clerk/jwt_verifier_spec.rb
# frozen_string_literal: true

require "rails_helper"
require "debug"

RSpec.describe Clerk::JwtVerifier do
  include ActiveSupport::Testing::TimeHelpers

  let(:jwks_url) { "https://example.test/.well-known/jwks.json" }
  let(:jwks_uri) { URI.parse(jwks_url) }

  # ✅ 実HTTPしない：get_response だけ使うので class_double で十分
  let(:http_client) { class_double(Net::HTTP) }

  # ✅ 通常テストはキャッシュ無効化（状態依存を減らす）
  let(:cache) { ActiveSupport::Cache::NullStore.new }
  let(:cache_key) { "spec:clerk:jwks" }
  let(:cache_ttl) { 5.minutes }
  let(:authorized_parties) { [] }

  subject(:verifier) do
    described_class.new(
      jwks_url: jwks_url,
      authorized_parties: authorized_parties,
      cache: cache,
      cache_key: cache_key,
      cache_ttl: cache_ttl,
      http_client: http_client
    )
  end

  describe ".verify!" do
    it "new(**options).verify!(token) を呼ぶ（hash_includingで保守性を上げる）" do
      instance = instance_double(described_class)

      expect(described_class).to receive(:new)
        .with(hash_including(cache: :cache, http_client: :http_client))
        .and_return(instance)

      expect(instance).to receive(:verify!).with("token").and_return({ "sub" => "user_1" })

      expect(described_class.verify!("token", cache: :cache, http_client: :http_client))
        .to include("sub" => "user_1")
    end
  end

  describe "#verify!" do
    it "token が nil/空/空白なら VerificationError（missing token）" do
      expect { verifier.verify!(nil) }
        .to raise_error(described_class::VerificationError, /\Amissing token\z/)

      expect { verifier.verify!("") }
        .to raise_error(described_class::VerificationError, /\Amissing token\z/)

      expect { verifier.verify!("   ") }
        .to raise_error(described_class::VerificationError, /\Amissing token\z/)
    end

    it "JWT::DecodeError を VerificationError にラップする（メッセージ保持）" do
      stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])

      allow(JWT).to receive(:decode)
        .and_raise(JWT::DecodeError.new("decode failed"))

      expect { verifier.verify!("dummy") }
        .to raise_error(described_class::VerificationError, /decode failed/)
    end

    context "azp チェック" do
      let(:authorized_parties) { ["http://localhost:8000"] }

      it "許可リストがある場合、azp が無い/空なら invalid azp" do
        stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])
        allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1" }, {}])

        expect { verifier.verify!("dummy") }
          .to raise_error(described_class::VerificationError, /\Ainvalid azp\z/)
      end

      it "許可リストがある場合、azp 不一致で invalid azp" do
        stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])
        allow(JWT).to receive(:decode)
          .and_return([{ "sub" => "user_1", "azp" => "http://localhost:9999" }, {}])

        expect { verifier.verify!("dummy") }
          .to raise_error(described_class::VerificationError, /\Ainvalid azp\z/)
      end

      it "許可リストがある場合、azp 一致なら payload を返す" do
        stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])
        allow(JWT).to receive(:decode)
          .and_return([{ "sub" => "user_1", "azp" => "http://localhost:8000" }, {}])

        expect(verifier.verify!("dummy")).to include("sub" => "user_1")
      end

      it "authorized_parties が文字列で渡っても正規化される（Array化）" do
        string_verifier = described_class.new(
          jwks_url: jwks_url,
          authorized_parties: "http://localhost:8000",
          cache: cache,
          cache_key: cache_key,
          cache_ttl: cache_ttl,
          http_client: http_client
        )

        stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])
        allow(JWT).to receive(:decode)
          .and_return([{ "sub" => "user_1", "azp" => "http://localhost:8000" }, {}])

        expect(string_verifier.verify!("dummy")).to include("sub" => "user_1")
      end

      it "authorized_parties がカンマ区切り文字列でも正規化される" do
        string_verifier = described_class.new(
          jwks_url: jwks_url,
          authorized_parties: "http://localhost:8000, http://localhost:9000",
          cache: cache,
          cache_key: cache_key,
          cache_ttl: cache_ttl,
          http_client: http_client
        )

        stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])
        allow(JWT).to receive(:decode)
        .and_return([{ "sub" => "user_1", "azp" => "http://localhost:9000" }, {}])

        expect(string_verifier.verify!("dummy")).to include("sub" => "user_1")
      end

    end
  end

  describe "JWKS fetch / JWT.decode 連携" do
    it "HTTP が成功し keys が取れれば JWT.decode に jwks が渡される" do
      stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])

      expect(JWT).to receive(:decode) do |_token, _key, _verify, options|
        expect(options[:jwks]).to eq({ keys: [{ "kty" => "RSA", "kid" => "1" }] })
        [{ "sub" => "user_1" }, {}]
      end

      verifier.verify!("dummy")
    end

    it "HTTP が失敗なら VerificationError（jwks fetch failed）" do
      stub_jwks_failure

      expect { verifier.verify!("dummy") }
        .to raise_error(described_class::VerificationError, /\Ajwks fetch failed\z/)
    end

    it "JWKS が JSON として壊れている場合は invalid jwks response" do
      stub_jwks_success_raw(body: "not json")

      expect { verifier.verify!("dummy") }
        .to raise_error(described_class::VerificationError, /invalid jwks response:/)
    end

    it "JWKS に keys が無い場合は invalid jwks response" do
      stub_jwks_success_raw(body: { "nope" => 1 }.to_json)

      expect { verifier.verify!("dummy") }
        .to raise_error(described_class::VerificationError, /invalid jwks response:/)
    end

    it "jwks_url が不正なら invalid jwks url" do
      bad = described_class.new(
        jwks_url: "::::", # URI.parse が落ちる
        authorized_parties: [],
        cache: cache,
        cache_key: cache_key,
        cache_ttl: cache_ttl,
        http_client: http_client
      )

      expect { bad.verify!("dummy") }
        .to raise_error(described_class::VerificationError, /invalid jwks url:/)
    end

    it "JWKS は cache に保存され、TTL内の2回目はHTTPを叩かない" do
      memory_cache = ActiveSupport::Cache::MemoryStore.new
      ttl = 5.minutes

      cached_verifier = described_class.new(
        jwks_url: jwks_url,
        authorized_parties: [],
        cache: memory_cache,
        cache_key: "spec:clerk:jwks:cache",
        cache_ttl: ttl,
        http_client: http_client
      )

      stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])
      allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1" }, {}])

      travel_to(Time.zone.parse("2026-01-01 00:00:00")) do
        cached_verifier.verify!("dummy") # 1回目: cache miss -> HTTP

        travel(ttl - 1.second)           # ✅ TTL内（境界値）
        cached_verifier.verify!("dummy") # 2回目: cache hit -> HTTPしない
      end

      expect(http_client).to have_received(:get_response).once
    end

    it "TTL を過ぎると JWKS を再取得する（HTTPを再度叩く）" do
      memory_cache = ActiveSupport::Cache::MemoryStore.new
      ttl = 5.minutes

      cached_verifier = described_class.new(
        jwks_url: jwks_url,
        authorized_parties: [],
        cache: memory_cache,
        cache_key: "spec:clerk:jwks:ttl",
        cache_ttl: ttl,
        http_client: http_client
      )

      # 1回目と2回目で異なる JWKS を返して「再取得」を見分ける
      keys1 = [{ "kty" => "RSA", "kid" => "1" }]
      keys2 = [{ "kty" => "RSA", "kid" => "2" }]

      success1 = instance_double("Net::HTTPSuccess", body: { "keys" => keys1 }.to_json)
      allow(success1).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      success2 = instance_double("Net::HTTPSuccess", body: { "keys" => keys2 }.to_json)
      allow(success2).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      allow(http_client).to receive(:get_response).with(jwks_uri).and_return(success1, success2)

      call = 0
      expect(JWT).to receive(:decode).twice do |_token, _key, _verify, options|
        call += 1
        expect(options[:jwks]).to eq({ keys: (call == 1 ? keys1 : keys2) })
        [{ "sub" => "user_1" }, {}]
      end

      travel_to(Time.zone.parse("2026-01-01 00:00:00")) do
        cached_verifier.verify!("dummy") # 1回目: cache miss -> HTTP 1回目

        travel(ttl + 1.second)           # ✅ TTL超過（境界値）
        cached_verifier.verify!("dummy") # 2回目: cache expire -> HTTP 2回目
      end

      expect(http_client).to have_received(:get_response).twice
    end
  end

  # ----------------------
  # helper methods
  # ----------------------

  def stub_jwks_success(keys:)
    stub_jwks_success_raw(body: { "keys" => keys }.to_json)
  end

  def stub_jwks_success_raw(body:)
    success = instance_double("Net::HTTPSuccess", body: body)
    allow(success).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

    allow(http_client).to receive(:get_response).with(jwks_uri).and_return(success)
  end

  def stub_jwks_failure
    failure = instance_double("Net::HTTPResponse", body: "nope")
    allow(failure).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)

    allow(http_client).to receive(:get_response).with(jwks_uri).and_return(failure)
  end
end
