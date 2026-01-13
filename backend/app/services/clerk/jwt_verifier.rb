# frozen_string_literal: true

require "net/http"
require "json"
require "jwt"

module Clerk
  class JwtVerifier
    class VerificationError < StandardError; end

    JWKS_CACHE_TTL = 5.minutes

    class << self
      def verify!(token)
        raise VerificationError, "missing token" if token.blank?

        payload, _header = decode_and_verify!(token)

        authorized_parties = authorized_parties_from_env
        if authorized_parties.any?
          azp = payload["azp"].to_s
          raise VerificationError, "invalid azp" unless authorized_parties.include?(azp)
        end

        payload
      rescue JWT::DecodeError => e
        raise VerificationError, e.message
      end

      private

      def decode_and_verify!(token)
        jwks = fetch_jwks!
        JWT.decode(token, nil, true, algorithms: ["RS256"], jwks: jwks)
      end

      def fetch_jwks!
        Rails.cache.fetch("clerk:jwks", expires_in: JWKS_CACHE_TTL) do
          uri = URI.parse(ENV.fetch("CLERK_JWKS_URL"))
          res = Net::HTTP.get_response(uri)
          raise VerificationError, "jwks fetch failed" unless res.is_a?(Net::HTTPSuccess)

          body = JSON.parse(res.body)
          { keys: body.fetch("keys") }
        rescue JSON::ParserError, KeyError
          raise VerificationError, "jwks parse failed"
        end
      end

      def authorized_parties_from_env
        ENV.fetch("CLERK_AUTHORIZED_PARTIES", "")
           .split(",")
           .map(&:strip)
           .reject(&:empty?)
      end
    end
  end
end
