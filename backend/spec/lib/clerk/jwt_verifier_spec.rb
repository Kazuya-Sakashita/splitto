require "rails_helper"

RSpec.describe Clerk::JwtVerifier do
  describe ".verify!" do
    it "token が空なら VerificationError（message表示）" do
      expect { described_class.verify!(nil) }
        .to raise_error(Clerk::JwtVerifier::VerificationError) { |e| warn "VerificationError(nil): #{e.message}" }

      expect { described_class.verify!("") }
        .to raise_error(Clerk::JwtVerifier::VerificationError) { |e| warn "VerificationError(empty): #{e.message}" }
    end

    it "JWT::DecodeError を VerificationError にラップする（message表示）" do
      allow(described_class).to receive(:decode_and_verify!)
        .and_raise(JWT::DecodeError.new("decode failed"))

      expect { described_class.verify!("dummy") }
        .to raise_error(Clerk::JwtVerifier::VerificationError, /decode failed/) { |e| warn "VerificationError: #{e.message}" }
    end

    it "CLERK_AUTHORIZED_PARTIES がある場合、azp 不一致で VerificationError（message表示）" do
      original = ENV["CLERK_AUTHORIZED_PARTIES"]
      ENV["CLERK_AUTHORIZED_PARTIES"] = "a,b"

      allow(described_class).to receive(:decode_and_verify!)
        .and_return([{ "sub" => "user_1", "azp" => "x" }, {}])

      expect { described_class.verify!("dummy") }
        .to raise_error(Clerk::JwtVerifier::VerificationError, /invalid azp/) { |e| warn "VerificationError: #{e.message}" }
    ensure
      ENV["CLERK_AUTHORIZED_PARTIES"] = original
    end
  end
end
