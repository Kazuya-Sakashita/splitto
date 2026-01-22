# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clerk::JwtVerifier do
  include ActiveSupport::Testing::TimeHelpers

  let(:jwks_url) { "https://example.test/.well-known/jwks.json" }
  let(:jwks_uri) { URI.parse(jwks_url) }

  let(:authorized_parties) { [] }

  let(:http_client) { class_double(Net::HTTP) }
  let(:cache) { ActiveSupport::Cache::NullStore.new }
  let(:cache_key) { "spec:clerk:jwks" }
  let(:cache_ttl) { 5.minutes }

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
    subject(:call_verify!) { described_class.verify!(token, **options) }

    let(:token) { "token" }
    let(:options) { { cache: :cache, http_client: :http_client } }

    it "new(**options).verify!(token) を呼ぶ" do
      instance = instance_double(described_class)

      expect(described_class).to receive(:new).with(hash_including(options)).and_return(instance)
      expect(instance).to receive(:verify!).with(token).and_return({ "sub" => "user_1" })

      expect(call_verify!).to include("sub" => "user_1")
    end
  end

  describe "#verify!" do
    subject(:call_verify!) { verifier.verify!(token) }

    let(:token) { "dummy" }

    context "token が nil/空/空白のとき" do
      let(:token) { "" }

      it "VerificationError（missing token）を投げる" do
        expect { call_verify! }
          .to raise_error(described_class::VerificationError, /\Amissing token\z/)
      end
    end

    context "JWT.decode が JWT::DecodeError を投げるとき" do
      before do
        stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])
        allow(JWT).to receive(:decode).and_raise(JWT::DecodeError.new("decode failed"))
      end

      it "VerificationError にラップして投げる（メッセージ保持）" do
        expect { call_verify! }
          .to raise_error(described_class::VerificationError, /decode failed/)
      end
    end

    context "JWT.decode が成功するとき" do
      let(:azp) { "http://localhost:8000" }
      let(:payload) { { "sub" => "user_1", "azp" => azp } }

      before do
        stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])
        allow(JWT).to receive(:decode).and_return([payload, {}])
      end

      context "authorized_parties が空のとき" do
        let(:authorized_parties) { [] }

        it "payload を返す" do
          expect(call_verify!).to include("sub" => "user_1")
        end
      end

      context "authorized_parties が存在するとき" do
        let(:authorized_parties) { ["http://localhost:8000"] }

        context "payload に azp が無いとき" do
          let(:payload) { { "sub" => "user_1" } }

          it "VerificationError（invalid azp）を投げる" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /\Ainvalid azp\z/)
          end
        end

        context "azp が一致しないとき" do
          let(:azp) { "http://localhost:9999" }

          it "VerificationError（invalid azp）を投げる" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /\Ainvalid azp\z/)
          end
        end

        context "azp が一致するとき" do
          let(:azp) { "http://localhost:8000" }

          it "payload を返す" do
            expect(call_verify!).to include("sub" => "user_1")
          end
        end
      end

      context "authorized_parties の正規化" do
        context "authorized_parties が文字列（単体URL）のとき" do
          let(:authorized_parties) { "http://localhost:8000" }

          it "許可リストとして扱える" do
            expect(call_verify!).to include("sub" => "user_1")
          end
        end

        context "authorized_parties がカンマ区切り文字列のとき" do
          let(:authorized_parties) { "http://localhost:8000, http://localhost:9000" }
          let(:azp) { "http://localhost:9000" }

          it "（仕様にするなら）許可リストとして扱える" do
            expect(call_verify!).to include("sub" => "user_1")
          end
        end
      end
    end
  end

  describe "JWKS fetch / JWT.decode 連携" do
    subject(:call_verify!) { verifier.verify!(token) }

    let(:token) { "dummy" }

    before do
      allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1" }, {}])
    end

    context "HTTP が成功し keys が取れるとき" do
      let(:keys) { [{ "kty" => "RSA", "kid" => "1" }] }

      before do
        stub_jwks_success(keys: keys)
      end

      it "JWT.decode に jwks が渡される" do
        expect(JWT).to receive(:decode) do |_token, _key, _verify, options|
          expect(options[:jwks]).to eq({ keys: keys })
          [{ "sub" => "user_1" }, {}]
        end

        call_verify!
      end
    end

    context "HTTP が失敗するとき" do
      before do
        stub_jwks_failure
      end

      it "VerificationError（jwks fetch failed）を投げる" do
        expect { call_verify! }
          .to raise_error(described_class::VerificationError, /\Ajwks fetch failed\z/)
      end
    end

    context "JWKS が壊れているとき" do
      before do
        stub_jwks_success_raw(body: "not json")
      end

      it "VerificationError（invalid jwks response）を投げる" do
        expect { call_verify! }
          .to raise_error(described_class::VerificationError, /invalid jwks response:/)
      end
    end

    context "JWKS に keys が無いとき" do
      before do
        stub_jwks_success_raw(body: { "nope" => 1 }.to_json)
      end

      it "VerificationError（invalid jwks response）を投げる" do
        expect { call_verify! }
          .to raise_error(described_class::VerificationError, /invalid jwks response:/)
      end
    end

    context "jwks_url が不正なとき" do
      subject(:call_verify!) { invalid_verifier.verify!(token) }

      let(:token) { "dummy" }

      let(:invalid_verifier) do
        described_class.new(
          jwks_url: "::::",
          authorized_parties: [],
          cache: cache,
          cache_key: cache_key,
          cache_ttl: cache_ttl,
          http_client: http_client
        )
      end

      it "VerificationError（invalid jwks url）を投げる" do
        expect { call_verify! }
          .to raise_error(described_class::VerificationError, /invalid jwks url:/)
      end
    end

    context "JWKS cache" do
      let(:cache) { ActiveSupport::Cache::MemoryStore.new }
      let(:cache_ttl) { 5.minutes }

      before do
        stub_jwks_success(keys: [{ "kty" => "RSA", "kid" => "1" }])
      end

      it "TTL 内は HTTP を叩かない" do
        travel_to(Time.zone.parse("2026-01-01 00:00:00")) do
          verifier.verify!("dummy")

          travel(cache_ttl - 1.second)
          verifier.verify!("dummy")
        end

        expect(http_client).to have_received(:get_response).once
      end

      it "TTL を過ぎると再取得する" do
        keys1 = [{ "kty" => "RSA", "kid" => "1" }]
        keys2 = [{ "kty" => "RSA", "kid" => "2" }]

        success1 = instance_double("Net::HTTPSuccess", body: { "keys" => keys1 }.to_json)
        allow(success1).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

        success2 = instance_double("Net::HTTPSuccess", body: { "keys" => keys2 }.to_json)
        allow(success2).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

        allow(http_client).to receive(:get_response).with(jwks_uri).and_return(success1, success2)

        travel_to(Time.zone.parse("2026-01-01 00:00:00")) do
          verifier.verify!("dummy")

          travel(cache_ttl + 1.second)
          verifier.verify!("dummy")
        end

        expect(http_client).to have_received(:get_response).twice
      end
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
