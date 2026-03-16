# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/invites/:invite_token/membership", type: :request do
  subject(:do_request) do
    post "/api/v1/invites/#{target_invite_token}/membership", headers: request_headers
  end

  let!(:invite_token) { "join_token_123" }
  let!(:target_invite_token) { invite_token }
  let!(:group) { create(:group, invite_token: invite_token, name: "大阪旅行", currency: "JPY") }

  context "認証に成功したとき" do
    let!(:external_uid) { "clerk_user_123" }
    let!(:token) { "test-token" }
    let!(:headers) { { "Authorization" => "Bearer #{token}" } }
    let!(:request_headers) { headers }
    let!(:user) { create(:user, external_uid: external_uid) }

    before do
      allow(Clerk::JwtVerifier).to receive(:verify!).with(token).and_return(
        { "sub" => external_uid }
      )
    end

    context "未参加のユーザーのとき" do
      it "招待トークン経由で新規参加できる" do
        expect { do_request }.to change(Member, :count).by(1)

        expect(response).to have_http_status(:ok)
        assert_response_schema_confirm(200)

        body = response.parsed_body
        member = Member.find_by!(group: group, user: user)

        aggregate_failures do
          expect(body["member"]["id"]).to eq(member.id)
          expect(body["member"]["role"]).to eq("MEMBER")
          expect(body["member"]["active"]).to eq(true)
          expect(body["member"]["left_at"]).to be_nil
          expect(body["member"]["user"]["public_id"]).to eq(user.public_id)
          expect(body["member"]["group"]["public_id"]).to eq(group.public_id)
          expect(body["member"]["group"]["name"]).to eq("大阪旅行")
          expect(body["member"]["group"]["currency"]).to eq("JPY")

          expect(member.role).to eq("MEMBER")
          expect(member.active).to eq(true)
          expect(member.left_at).to be_nil
          expect(member.joined_at).to be_present
        end
      end
    end

    context "同じユーザーが連続で参加するとき" do
      it "二重参加せず冪等に動作する" do
        expect do
          do_request
          expect(response).to have_http_status(:ok)
          assert_response_schema_confirm(200)

          do_request
          expect(response).to have_http_status(:ok)
          assert_response_schema_confirm(200)
        end.to change(Member, :count).by(1)

        members = Member.where(group: group, user: user)

        aggregate_failures do
          expect(members.count).to eq(1)

          member = members.first
          expect(member.role).to eq("MEMBER")
          expect(member.active).to eq(true)
          expect(member.left_at).to be_nil
        end
      end
    end

    context "既に active な member が存在するとき" do
      let!(:existing_member) do
        create(
          :member,
          group: group,
          user: user,
          role: "MEMBER",
          active: true,
          joined_at: 1.day.ago,
          left_at: nil
        )
      end

      it "新規作成せず既存 member を返す" do
        expect { do_request }.not_to change(Member, :count)

        expect(response).to have_http_status(:ok)
        assert_response_schema_confirm(200)

        body = response.parsed_body
        existing_member.reload

        aggregate_failures do
          expect(body["member"]["id"]).to eq(existing_member.id)
          expect(body["member"]["role"]).to eq("MEMBER")
          expect(body["member"]["active"]).to eq(true)
          expect(body["member"]["left_at"]).to be_nil

          expect(existing_member.role).to eq("MEMBER")
          expect(existing_member.active).to eq(true)
          expect(existing_member.left_at).to be_nil
        end
      end
    end

    context "退出済みのメンバーのとき" do
      let!(:member) do
        create(
          :member,
          group: group,
          user: user,
          role: "MEMBER",
          active: false,
          joined_at: 7.days.ago,
          left_at: 1.day.ago
        )
      end

      it "再参加できる" do
        previous_joined_at = member.joined_at

        expect { do_request }.not_to change(Member, :count)

        expect(response).to have_http_status(:ok)
        assert_response_schema_confirm(200)

        body = response.parsed_body
        member.reload

        aggregate_failures do
          expect(body["member"]["id"]).to eq(member.id)
          expect(body["member"]["role"]).to eq("MEMBER")
          expect(body["member"]["active"]).to eq(true)
          expect(body["member"]["left_at"]).to be_nil

          expect(member.role).to eq("MEMBER")
          expect(member.active).to eq(true)
          expect(member.left_at).to be_nil
          expect(member.joined_at).to be_present
          expect(member.joined_at).not_to eq(previous_joined_at)
        end
      end
    end

    context "同時実行で既存 member が作成済みのとき" do
      let!(:existing_member) do
        create(
          :member,
          group: group,
          user: user,
          role: "MEMBER",
          active: true,
          joined_at: 1.day.ago,
          left_at: nil
        )
      end

      before do
        association = group.members

        allow(association).to receive(:find_by).with(user: user).and_return(nil)
        allow(association).to receive(:create_or_find_by!).with(user: user).and_return(existing_member)
        allow(Group).to receive(:find_by!).with(invite_token: invite_token).and_return(group)
      end

      it "既存 member を返し冪等に動作する" do
        expect { do_request }.not_to change(Member, :count)

        expect(response).to have_http_status(:ok)
        assert_response_schema_confirm(200)

        body = response.parsed_body

        aggregate_failures do
          expect(body["member"]["id"]).to eq(existing_member.id)
          expect(body["member"]["role"]).to eq("MEMBER")
          expect(body["member"]["active"]).to eq(true)
          expect(body["member"]["left_at"]).to be_nil
        end
      end
    end

    context "invite_token が不正なとき" do
      let!(:target_invite_token) { "invalid_token" }

      it "404 を返す" do
        expect { do_request }.not_to change(Member, :count)

        expect(response).to have_http_status(:not_found)
        expect(response.media_type).to eq("application/problem+json")
        assert_response_schema_confirm(404)

        body = response.parsed_body

        aggregate_failures do
          expect(body["reason"]).to eq("invalid_invite_token")
          expect(body["detail"]).to eq("invite_token is invalid")
        end
      end
    end
  end

  context "認証に失敗したとき" do
    before do
      allow(Clerk::JwtVerifier).to receive(:verify!)
    end

    context "Authorization ヘッダーがないとき" do
      let!(:request_headers) { {} }

      it "401 を返し verify! を呼ばない" do
        expect { do_request }.not_to change(Member, :count)

        expect(response).to have_http_status(:unauthorized)
        expect(response.media_type).to eq("application/problem+json")
        assert_response_schema_confirm(401)
        expect(Clerk::JwtVerifier).not_to have_received(:verify!)

        expect(response.parsed_body).to include(
          "title" => "Unauthorized",
          "status" => 401,
          "reason" => "missing_token"
        )
      end
    end

    context "トークンが不正なとき" do
      let!(:request_headers) { { "Authorization" => "Bearer invalid-token" } }

      before do
        allow(Clerk::JwtVerifier).to receive(:verify!).with("invalid-token").and_raise(
          Clerk::JwtVerifier::VerificationError,
          "invalid token"
        )
      end

      it "401 を返す" do
        expect { do_request }.not_to change(Member, :count)

        expect(response).to have_http_status(:unauthorized)
        expect(response.media_type).to eq("application/problem+json")
        assert_response_schema_confirm(401)

        expect(response.parsed_body).to include(
          "title" => "Unauthorized",
          "status" => 401,
          "reason" => "invalid_token"
        )
      end
    end
  end
end
