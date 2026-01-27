# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clerk::JwtVerifier do
  include ActiveSupport::Testing::TimeHelpers

  let(:jwks_url) { "https://example.test/.well-known/jwks.json" }

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

    context "共通前提" do
      let(:token) { "dummy" }
      let(:jwks_uri) { URI.parse(jwks_url) }

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

      describe "正常系" do
        let(:frontend_origin) { "http://localhost:8000" }

        context "authorized_parties が空のとき" do
          let(:authorized_parties) { [] }
          let(:payload) { { "sub" => "user_1", "azp" => frontend_origin } }

          before do
            stub_jwks_success(http_client: http_client, jwks_uri: jwks_uri, keys: [{ "kty" => "RSA", "kid" => "1" }])
            allow(JWT).to receive(:decode).and_return([payload, {}])
          end

          it "payload を返す" do
            expect(call_verify!).to include("sub" => "user_1")
          end
        end

        context "authorized_parties があり、azp が一致するとき" do
          let(:authorized_parties) { [frontend_origin] }
          let(:payload) { { "sub" => "user_1", "azp" => frontend_origin } }

          before do
            stub_jwks_success(http_client: http_client, jwks_uri: jwks_uri, keys: [{ "kty" => "RSA", "kid" => "1" }])
            allow(JWT).to receive(:decode).and_return([payload, {}])
          end

          it "payload を返す" do
            expect(call_verify!).to include("sub" => "user_1")
          end
        end

        context "authorized_parties の正規化: 単体URLの文字列のとき" do
          let(:authorized_parties) { frontend_origin }
          let(:payload) { { "sub" => "user_1", "azp" => frontend_origin } }

          before do
            stub_jwks_success(http_client: http_client, jwks_uri: jwks_uri, keys: [{ "kty" => "RSA", "kid" => "1" }])
            allow(JWT).to receive(:decode).and_return([payload, {}])
          end

          it "許可リストとして扱える" do
            expect(call_verify!).to include("sub" => "user_1")
          end
        end

        context "authorized_parties の正規化: カンマ区切り文字列のとき" do
          let(:authorized_parties) { "#{frontend_origin}, http://localhost:9000" }
          let(:payload) { { "sub" => "user_1", "azp" => "http://localhost:9000" } }

          before do
            stub_jwks_success(http_client: http_client, jwks_uri: jwks_uri, keys: [{ "kty" => "RSA", "kid" => "1" }])
            allow(JWT).to receive(:decode).and_return([payload, {}])
          end

          it "許可リストとして扱える" do
            expect(call_verify!).to include("sub" => "user_1")
          end
        end
      end

      describe "異常系" do
        context "token が nil のとき" do
          let(:token) { nil }
          let(:authorized_parties) { [] }

          it "VerificationError（missing token）を投げる" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /\Amissing token\z/)
          end
        end

        context "token が空文字のとき" do
          let(:token) { "" }
          let(:authorized_parties) { [] }

          it "VerificationError（missing token）を投げる" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /\Amissing token\z/)
          end
        end

        context "token が空白だけのとき" do
          let(:token) { "   " }
          let(:authorized_parties) { [] }

          it "VerificationError（missing token）を投げる" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /\Amissing token\z/)
          end
        end

        context "JWT.decode が JWT::DecodeError を投げるとき" do
          let(:authorized_parties) { [] }

          before do
            stub_jwks_success(http_client: http_client, jwks_uri: jwks_uri, keys: [{ "kty" => "RSA", "kid" => "1" }])
            allow(JWT).to receive(:decode).and_raise(JWT::DecodeError.new("decode failed"))
          end

          it "VerificationError にラップして投げる（メッセージ保持）" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /decode failed/)
          end
        end

        context "authorized_parties があり、payload に azp が無いとき" do
          let(:frontend_origin) { "http://localhost:8000" }
          let(:authorized_parties) { [frontend_origin] }
          let(:payload) { { "sub" => "user_1" } }

          before do
            stub_jwks_success(http_client: http_client, jwks_uri: jwks_uri, keys: [{ "kty" => "RSA", "kid" => "1" }])
            allow(JWT).to receive(:decode).and_return([payload, {}])
          end

          it "VerificationError（invalid azp）を投げる" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /\Ainvalid azp\z/)
          end
        end

        context "authorized_parties があり、azp が一致しないとき" do
          let(:frontend_origin) { "http://localhost:8000" }
          let(:authorized_parties) { [frontend_origin] }
          let(:payload) { { "sub" => "user_1", "azp" => "http://localhost:9999" } }

          before do
            stub_jwks_success(http_client: http_client, jwks_uri: jwks_uri, keys: [{ "kty" => "RSA", "kid" => "1" }])
            allow(JWT).to receive(:decode).and_return([payload, {}])
          end

          it "VerificationError（invalid azp）を投げる" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /\Ainvalid azp\z/)
          end
        end
      end
    end
  end

  describe "JWKS fetch / JWT.decode 連携" do
    subject(:call_verify!) { verifier.verify!(token) }

    context "共通前提" do
      let(:token) { "dummy" }
      let(:authorized_parties) { [] }
      let(:jwks_uri) { URI.parse(jwks_url) }

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

      before do
        allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1" }, {}])
      end

      describe "正常系" do
        context "HTTP が成功し keys が取れるとき" do
          let(:keys) { [{ "kty" => "RSA", "kid" => "1" }] }

          before do
            stub_jwks_success(http_client: http_client, jwks_uri: jwks_uri, keys: keys)
          end

          it "JWT.decode に jwks が渡される" do
            expect(JWT).to receive(:decode) do |_token, _key, _verify, options|
              expect(options[:jwks]).to eq({ keys: keys })
              [{ "sub" => "user_1" }, {}]
            end

            call_verify!
          end
        end
      end

      describe "異常系" do
        context "HTTP が失敗するとき" do
          before do
            stub_jwks_failure(http_client: http_client, jwks_uri: jwks_uri)
          end

          it "VerificationError（jwks fetch failed）を投げる" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /\Ajwks fetch failed\z/)
          end
        end

        context "JWKS が壊れているとき" do
          before do
            stub_jwks_success_raw(http_client: http_client, jwks_uri: jwks_uri, body: "not json")
          end

          it "VerificationError（invalid jwks response）を投げる" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /invalid jwks response:/)
          end
        end

        context "JWKS に keys が無いとき" do
          before do
            stub_jwks_success_raw(http_client: http_client, jwks_uri: jwks_uri, body: { "nope" => 1 }.to_json)
          end

          it "VerificationError（invalid jwks response）を投げる" do
            expect { call_verify! }
              .to raise_error(described_class::VerificationError, /invalid jwks response:/)
          end
        end

        context "jwks_url が不正なとき" do
          subject(:call_verify!) { invalid_verifier.verify!(token) }

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
      end

      describe "キャッシュ" do
        let(:cache) { ActiveSupport::Cache::MemoryStore.new }
        let(:keys1) { [{ "kty" => "RSA", "kid" => "1" }] }
        let(:keys2) { [{ "kty" => "RSA", "kid" => "2" }] }

        before do
          stub_jwks_success_sequence(http_client: http_client, jwks_uri: jwks_uri, keys1: keys1, keys2: keys2)
        end

        context "TTL 内のとき" do
          before do
            travel_to(Time.zone.parse("2026-01-01 00:00:00")) do
              verifier.verify!(token)
              travel(cache_ttl - 1.second)
              verifier.verify!(token)
            end
          end

          it "HTTP を 1 回だけ叩く" do
            expect(http_client).to have_received(:get_response).once
          end
        end

        context "TTL を過ぎたとき" do
          before do
            travel_to(Time.zone.parse("2026-01-01 00:00:00")) do
              verifier.verify!(token)
              travel(cache_ttl + 1.second)
              verifier.verify!(token)
            end
          end

          it "HTTP を 2 回叩く（再取得する）" do
            expect(http_client).to have_received(:get_response).twice
          end
        end
      end
    end
  end

  # ----------------------
  # helper methods
  # ----------------------
  def stub_jwks_success(http_client:, jwks_uri:, keys:)
    stub_jwks_success_raw(http_client: http_client, jwks_uri: jwks_uri, body: { "keys" => keys }.to_json)
  end

  def stub_jwks_success_raw(http_client:, jwks_uri:, body:)
    success = instance_double("Net::HTTPSuccess", body: body)
    allow(success).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    allow(http_client).to receive(:get_response).with(jwks_uri).and_return(success)
  end

  def stub_jwks_failure(http_client:, jwks_uri:)
    failure = instance_double("Net::HTTPResponse", body: "nope")
    allow(failure).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
    allow(http_client).to receive(:get_response).with(jwks_uri).and_return(failure)
  end

  def stub_jwks_success_sequence(http_client:, jwks_uri:, keys1:, keys2:)
    success1 = instance_double("Net::HTTPSuccess", body: { "keys" => keys1 }.to_json)
    allow(success1).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

    success2 = instance_double("Net::HTTPSuccess", body: { "keys" => keys2 }.to_json)
    allow(success2).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

    allow(http_client).to receive(:get_response).with(jwks_uri).and_return(success1, success2)
  end
end
