
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Clerk::JwtVerifier do
  include ActiveSupport::Testing::TimeHelpers

  describe ".verify!" do
    let!(:token) { "token" }
    let!(:options) { { cache: :cache, http_client: :http_client } }
    let!(:instance) { instance_double(described_class) }

    before do
      allow(described_class).to receive(:new).with(hash_including(options)).and_return(instance)
      allow(instance).to receive(:verify!).with(token).and_return({ "sub" => "user_1" })
    end

    it "インスタンスを生成して #verify! に委譲する" do
      result = described_class.verify!(token, **options)

      expect(described_class).to have_received(:new).with(hash_including(options))
      expect(instance).to have_received(:verify!).with(token)
      expect(result).to include("sub" => "user_1")
    end
  end

  describe "#verify!" do
    describe "トークン検証" do
      context "有効なトークンのとき" do
        context "authorized_parties が未設定のとき" do
          let!(:http_client) { class_double(Net::HTTP) }
          let!(:verifier) do
            described_class.new(
              jwks_url: "https://example.test/.well-known/jwks.json",
              authorized_parties: [],
              cache: ActiveSupport::Cache::NullStore.new,
              http_client: http_client
            )
          end

          before do
            jwks_response = instance_double("Net::HTTPSuccess", body: { "keys" => [{ "kty" => "RSA", "kid" => "1" }] }.to_json)
            allow(jwks_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
            allow(http_client).to receive(:get_response).and_return(jwks_response)
            allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1", "azp" => "http://localhost:8000" }, {}])
          end

          it "デコードされた payload を返す" do
            expect(verifier.verify!("dummy")).to include("sub" => "user_1")
          end
        end

        context "authorized_parties が配列で設定されているとき" do
          let!(:http_client) { class_double(Net::HTTP) }
          let!(:verifier) do
            described_class.new(
              jwks_url: "https://example.test/.well-known/jwks.json",
              authorized_parties: ["http://localhost:8000"],
              cache: ActiveSupport::Cache::NullStore.new,
              http_client: http_client
            )
          end

          before do
            jwks_response = instance_double("Net::HTTPSuccess", body: { "keys" => [{ "kty" => "RSA", "kid" => "1" }] }.to_json)
            allow(jwks_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
            allow(http_client).to receive(:get_response).and_return(jwks_response)
            allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1", "azp" => "http://localhost:8000" }, {}])
          end

          it "azp が一致すれば payload を返す" do
            expect(verifier.verify!("dummy")).to include("sub" => "user_1")
          end
        end

        context "authorized_parties が単体URL文字列のとき" do
          let!(:http_client) { class_double(Net::HTTP) }
          let!(:verifier) do
            described_class.new(
              jwks_url: "https://example.test/.well-known/jwks.json",
              authorized_parties: "http://localhost:8000",
              cache: ActiveSupport::Cache::NullStore.new,
              http_client: http_client
            )
          end

          before do
            jwks_response = instance_double("Net::HTTPSuccess", body: { "keys" => [{ "kty" => "RSA", "kid" => "1" }] }.to_json)
            allow(jwks_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
            allow(http_client).to receive(:get_response).and_return(jwks_response)
            allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1", "azp" => "http://localhost:8000" }, {}])
          end

          it "配列に正規化されて azp 検証が行われる" do
            expect(verifier.verify!("dummy")).to include("sub" => "user_1")
          end
        end

        context "authorized_parties がカンマ区切り文字列のとき" do
          let!(:http_client) { class_double(Net::HTTP) }
          let!(:verifier) do
            described_class.new(
              jwks_url: "https://example.test/.well-known/jwks.json",
              authorized_parties: "http://localhost:8000, http://localhost:9000",
              cache: ActiveSupport::Cache::NullStore.new,
              http_client: http_client
            )
          end

          before do
            jwks_response = instance_double("Net::HTTPSuccess", body: { "keys" => [{ "kty" => "RSA", "kid" => "1" }] }.to_json)
            allow(jwks_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
            allow(http_client).to receive(:get_response).and_return(jwks_response)
            allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1", "azp" => "http://localhost:9000" }, {}])
          end

          it "分割されて複数の許可オリジンとして扱われる" do
            expect(verifier.verify!("dummy")).to include("sub" => "user_1")
          end
        end
      end

      context "無効なトークンのとき" do
        let!(:verifier) do
          described_class.new(
            jwks_url: "https://example.test/.well-known/jwks.json",
            authorized_parties: [],
            cache: ActiveSupport::Cache::NullStore.new,
            http_client: class_double(Net::HTTP)
          )
        end

        context "nil のとき" do
          it "VerificationError を raise する" do
            expect { verifier.verify!(nil) }
              .to raise_error(described_class::VerificationError, "missing token")
          end
        end

        context "空文字のとき" do
          it "VerificationError を raise する" do
            expect { verifier.verify!("") }
              .to raise_error(described_class::VerificationError, "missing token")
          end
        end

        context "空白のみのとき" do
          it "VerificationError を raise する" do
            expect { verifier.verify!("   ") }
              .to raise_error(described_class::VerificationError, "missing token")
          end
        end
      end
    end

    describe "JWT デコード" do
      context "JWT.decode が DecodeError を raise するとき" do
        let!(:http_client) { class_double(Net::HTTP) }
        let!(:verifier) do
          described_class.new(
            jwks_url: "https://example.test/.well-known/jwks.json",
            authorized_parties: [],
            cache: ActiveSupport::Cache::NullStore.new,
            http_client: http_client
          )
        end

        before do
          jwks_response = instance_double("Net::HTTPSuccess", body: { "keys" => [{ "kty" => "RSA", "kid" => "1" }] }.to_json)
          allow(jwks_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(http_client).to receive(:get_response).and_return(jwks_response)
          allow(JWT).to receive(:decode).and_raise(JWT::DecodeError.new("decode failed"))
        end

        it "VerificationError にラップして raise する" do
          expect { verifier.verify!("dummy") }
            .to raise_error(described_class::VerificationError, "decode failed")
        end
      end
    end

    describe "azp (Authorized Party) 検証" do
      let!(:http_client) { class_double(Net::HTTP) }
      let!(:verifier) do
        described_class.new(
          jwks_url: "https://example.test/.well-known/jwks.json",
          authorized_parties: ["http://localhost:8000"],
          cache: ActiveSupport::Cache::NullStore.new,
          http_client: http_client
        )
      end

      before do
        jwks_response = instance_double("Net::HTTPSuccess", body: { "keys" => [{ "kty" => "RSA", "kid" => "1" }] }.to_json)
        allow(jwks_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(http_client).to receive(:get_response).and_return(jwks_response)
      end

      context "payload に azp クレームが存在しないとき" do
        before do
          allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1" }, {}])
        end

        it "VerificationError を raise する" do
          expect { verifier.verify!("dummy") }
            .to raise_error(described_class::VerificationError, "invalid azp")
        end
      end

      context "azp が authorized_parties に含まれないとき" do
        before do
          allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1", "azp" => "http://localhost:9999" }, {}])
        end

        it "VerificationError を raise する" do
          expect { verifier.verify!("dummy") }
            .to raise_error(described_class::VerificationError, "invalid azp")
        end
      end
    end

    describe "JWKS 取得" do
      let!(:http_client) { class_double(Net::HTTP) }
      let!(:verifier) do
        described_class.new(
          jwks_url: "https://example.test/.well-known/jwks.json",
          authorized_parties: [],
          cache: ActiveSupport::Cache::NullStore.new,
          http_client: http_client
        )
      end

      context "HTTP リクエストが成功するとき" do
        before do
          jwks_response = instance_double("Net::HTTPSuccess", body: { "keys" => [{ "kty" => "RSA", "kid" => "1" }] }.to_json)
          allow(jwks_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(http_client).to receive(:get_response).and_return(jwks_response)
          allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1" }, {}])
        end

        it "取得した JWKS を JWT.decode に渡す" do
          expect(JWT).to receive(:decode) do |_token, _key, _verify, options|
            expect(options[:jwks]).to eq({ keys: [{ "kty" => "RSA", "kid" => "1" }] })
            [{ "sub" => "user_1" }, {}]
          end

          verifier.verify!("dummy")
        end
      end

      context "HTTP リクエストが失敗するとき" do
        before do
          failure_response = instance_double("Net::HTTPResponse", body: "error")
          allow(failure_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
          allow(http_client).to receive(:get_response).and_return(failure_response)
        end

        it "VerificationError を raise する" do
          expect { verifier.verify!("dummy") }
            .to raise_error(described_class::VerificationError, "jwks fetch failed")
        end
      end

      context "レスポンスが不正な JSON のとき" do
        before do
          invalid_response = instance_double("Net::HTTPSuccess", body: "not json")
          allow(invalid_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(http_client).to receive(:get_response).and_return(invalid_response)
        end

        it "VerificationError を raise する" do
          expect { verifier.verify!("dummy") }
            .to raise_error(described_class::VerificationError, /invalid jwks response:/)
        end
      end

      context "レスポンスに keys が存在しないとき" do
        before do
          no_keys_response = instance_double("Net::HTTPSuccess", body: { "nope" => 1 }.to_json)
          allow(no_keys_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(http_client).to receive(:get_response).and_return(no_keys_response)
        end

        it "VerificationError を raise する" do
          expect { verifier.verify!("dummy") }
            .to raise_error(described_class::VerificationError, /invalid jwks response:/)
        end
      end

      context "jwks_url が不正なとき" do
        let!(:invalid_verifier) do
          described_class.new(
            jwks_url: "::::",
            authorized_parties: [],
            cache: ActiveSupport::Cache::NullStore.new,
            http_client: http_client
          )
        end

        it "VerificationError を raise する" do
          expect { invalid_verifier.verify!("dummy") }
            .to raise_error(described_class::VerificationError, /invalid jwks url:/)
        end
      end
    end

    describe "JWKS キャッシュ" do
      let!(:http_client) { class_double(Net::HTTP) }
      let!(:verifier) do
        described_class.new(
          jwks_url: "https://example.test/.well-known/jwks.json",
          authorized_parties: [],
          cache: ActiveSupport::Cache::MemoryStore.new,
          cache_ttl: 5.minutes,
          http_client: http_client
        )
      end

      before do
        allow(JWT).to receive(:decode).and_return([{ "sub" => "user_1" }, {}])

        first_response = instance_double("Net::HTTPSuccess", body: { "keys" => [{ "kty" => "RSA", "kid" => "1" }] }.to_json)
        allow(first_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

        second_response = instance_double("Net::HTTPSuccess", body: { "keys" => [{ "kty" => "RSA", "kid" => "2" }] }.to_json)
        allow(second_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

        allow(http_client).to receive(:get_response).and_return(first_response, second_response)
      end

      context "キャッシュ有効期間内に複数回呼び出すとき" do
        it "HTTP リクエストは 1 回のみ実行される" do
          travel_to(Time.zone.parse("2026-01-01 00:00:00")) do
            verifier.verify!("dummy")
            travel(5.minutes - 1.second)
            verifier.verify!("dummy")
          end

          expect(http_client).to have_received(:get_response).once
        end
      end

      context "キャッシュ有効期間を過ぎて呼び出すとき" do
        it "HTTP リクエストが再度実行される" do
          travel_to(Time.zone.parse("2026-01-01 00:00:00")) do
            verifier.verify!("dummy")
            travel(5.minutes + 1.second)
            verifier.verify!("dummy")
          end

          expect(http_client).to have_received(:get_response).twice
        end
      end
    end
  end
end
