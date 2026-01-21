# frozen_string_literal: true

require "net/http"
require "json"
require "jwt"

module Clerk
  class JwtVerifier
    class VerificationError < StandardError; end

    DEFAULT_JWKS_CACHE_TTL = 5.minutes
    DEFAULT_JWKS_CACHE_KEY = "clerk:jwks"

    class << self
      # 呼び出し側は基本これだけ（token だけ渡す）
      # 必要になったら DI（cache/http_client/jwks_url/authorized_parties など）を options で差し替え可能
      def verify!(token, **options)
        new(**options).verify!(token)
      end

      # ENV 由来の authorized_parties を共通化（余計な空白や空要素は除去）
      def env_authorized_parties
        ENV["CLERK_AUTHORIZED_PARTIES"].to_s
          .split(",")
          .map(&:strip)
          .reject(&:empty?)
      end
    end

    def initialize(
      jwks_url: ENV.fetch("CLERK_JWKS_URL"),
      authorized_parties: self.class.env_authorized_parties,
      cache: Rails.cache,
      cache_key: DEFAULT_JWKS_CACHE_KEY,
      cache_ttl: DEFAULT_JWKS_CACHE_TTL,
      http_client: Net::HTTP
    )
      @jwks_url = jwks_url
      @authorized_parties = normalize_authorized_parties(authorized_parties)
      @cache = cache
      @cache_key = cache_key
      @cache_ttl = cache_ttl
      @http_client = http_client
    end

    def verify!(token)
      token_str = token.to_s.strip
      raise VerificationError, "missing token" if token_str.empty?

      payload, _header = decode_and_verify!(token_str)
      validate_azp!(payload)

      payload
    rescue JWT::DecodeError => e
      # 呼び出し側で一律に扱えるように例外を統一
      raise VerificationError, e.message
    end

    private

    attr_reader :jwks_url, :authorized_parties, :cache, :cache_key, :cache_ttl, :http_client

    def normalize_authorized_parties(value)
      case value
      when nil
        []
      when String
        value.split(",").map(&:strip).reject(&:empty?)
      else
        Array(value).map(&:to_s).map(&:strip).reject(&:empty?)
      end
    end


    # authorized_parties を設定している場合のみ azp を検証する
    def validate_azp!(payload)
      return if authorized_parties.empty?

      azp = payload["azp"].to_s.strip
      return if !azp.empty? && authorized_parties.include?(azp)

      raise VerificationError, "invalid azp"
    end

    def decode_and_verify!(token)
      jwks = fetch_jwks!
      JWT.decode(token, nil, true, algorithms: ["RS256"], jwks: jwks)
    end

    def fetch_jwks!
      cache.fetch(cache_key, expires_in: cache_ttl) do
        uri = URI.parse(jwks_url)
        res = http_client.get_response(uri)

        raise VerificationError, "jwks fetch failed" unless res.is_a?(Net::HTTPSuccess)

        body = JSON.parse(res.body)
        keys = body.fetch("keys") # keys が無ければ KeyError

        # jwt gem が期待する形式
        { keys: keys }
      end
    rescue JSON::ParserError, KeyError => e
      raise VerificationError, "invalid jwks response: #{e.message}"
    rescue URI::InvalidURIError => e
      raise VerificationError, "invalid jwks url: #{e.message}"
    end
  end
end
