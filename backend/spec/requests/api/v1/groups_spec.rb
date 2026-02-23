# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Groups API", type: :request do
  describe "POST /api/v1/groups" do
    subject(:do_request) { post "/api/v1/groups", params: params, headers: headers, as: :json }

    describe "認証" do
      context "認証成功（Authorization: Bearer / verify! 成功）" do
        let!(:token) { "dummy" }
        let!(:allowed_origin) { ENV.fetch("CORS_ALLOWED_ORIGIN", "http://localhost:8000") }
        let!(:sub) { "user_abc" }
        let!(:payload) { { "sub" => sub, "azp" => allowed_origin } }

        let!(:headers) do
          {
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json"
          }
        end

        let!(:user) { create(:user, external_uid: sub) }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!).and_return(payload)
        end

        context "パラメータが正常なとき" do
          let!(:params) { { group: { name: "旅行精算", currency: "JPY" } } }

          it "201 を返し、Group を作成し、作成者を OWNER として members に登録する" do
            expect { do_request }
              .to change(Group, :count).by(1)
              .and change(Member, :count).by(1)

            expect(response).to have_http_status(:created)
            assert_response_schema_confirm(201)

            created_group = Group.order(:id).last
            created_member = Member.order(:id).last

            expect(created_group).to have_attributes(
              name: "旅行精算",
              currency: "JPY"
            )
            expect(created_group.public_id).to be_present
            expect(created_group.invite_token).to be_present

            expect(created_member).to have_attributes(
              group_id: created_group.id,
              user_id: user.id,
              role: "OWNER",
              active: true
            )
            expect(created_member.joined_at).to be_present
            expect(created_member.left_at).to be_nil

            body = response.parsed_body
            expect(body).to include("group")

            group_json = body.fetch("group")
            expect(group_json).to include(
              "public_id" => created_group.public_id,
              "name" => "旅行精算",
              "currency" => "JPY",
              "invite_token" => created_group.invite_token
            )
            expect(group_json["created_at"]).to be_a(String)
            expect(group_json["updated_at"]).to be_a(String)
          end
        end

        context "name が不正なとき（空文字）" do
          let!(:params) { { group: { name: "", currency: "JPY" } } }

          it "422 を返し、Group / Member を作成しない（Problem Details）" do
            expect { do_request }
              .to change(Group, :count).by(0)
              .and change(Member, :count).by(0)

            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.media_type).to eq("application/problem+json")
            assert_response_schema_confirm(422)

            body = response.parsed_body
            expect(body).to include(
              "title" => "Unprocessable Entity",
              "status" => 422,
              "reason" => "validation_error"
            )

            expect(body["errors"]).to be_a(Hash)
            expect(body["errors"]).to include("name")
            expect(body["errors"]["name"]).to be_an(Array)
          end
        end
      end

      context "認証失敗（Authorization ヘッダーなし）" do
        let!(:headers) { { "Content-Type" => "application/json" } }
        let!(:params) { { group: { name: "旅行精算", currency: "JPY" } } }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!)
        end

        it "401 missing_token を返す（Problem Details）" do
          do_request

          expect(response).to have_http_status(:unauthorized)
          expect(response.media_type).to eq("application/problem+json")
          assert_response_schema_confirm(401)

          expect(response.parsed_body).to include(
            "title" => "Unauthorized",
            "status" => 401,
            "reason" => "missing_token"
          )
        end

        it "Clerk::JwtVerifier.verify! を呼ばない" do
          do_request
          expect(Clerk::JwtVerifier).not_to have_received(:verify!)
        end
      end

      context "認証失敗（Authorization: Bearer / verify! 失敗）" do
        let!(:token) { "dummy" }
        let!(:headers) do
          {
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json"
          }
        end
        let!(:params) { { group: { name: "旅行精算", currency: "JPY" } } }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!)
            .and_raise(Clerk::JwtVerifier::VerificationError.new("decode failed"))
        end

        it "401 invalid_token を返す（Problem Details）" do
          do_request

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

  describe "GET /api/v1/groups" do
    subject(:do_request) { get "/api/v1/groups", params: query, headers: headers }

    let(:query) { {} }

    describe "認証" do
      context "認証成功（Authorization: Bearer / verify! 成功）" do
        let!(:token) { "dummy" }
        let!(:allowed_origin) { ENV.fetch("CORS_ALLOWED_ORIGIN", "http://localhost:8000") }
        let!(:sub) { "user_abc" }
        let!(:payload) { { "sub" => sub, "azp" => allowed_origin } }

        let!(:headers) do
          {
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json"
          }
        end

        let!(:user) { create(:user, external_uid: sub) }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!).and_return(payload)
        end

        context "所属グループがあるとき（基本）" do
          let!(:active_newer_group) { create(:group, name: "新しい", currency: "JPY", updated_at: 2.hours.ago) }
          let!(:active_older_group) { create(:group, name: "古い", currency: "JPY", updated_at: 2.days.ago) }
          let!(:inactive_group) { create(:group, name: "退出済み", currency: "JPY") }
          let!(:other_users_group) { create(:group, name: "他人のグループ", currency: "JPY") }

          let!(:other_user) { create(:user) }
          let!(:third_user) { create(:user) }

          before do
            create(:member, user: user, group: active_newer_group, active: true, role: "MEMBER", joined_at: Time.current)
            create(:member, user: user, group: active_older_group, active: true, role: "MEMBER", joined_at: Time.current)

            create(:member, user: other_user, group: active_newer_group, active: true, role: "MEMBER", joined_at: Time.current)

            create(:member, user: user, group: inactive_group, active: false, role: "MEMBER", joined_at: Time.current, left_at: Time.current)

            create(:member, user: third_user, group: other_users_group, active: true, role: "MEMBER", joined_at: Time.current)
          end

          it "200 を返し、自分の active=true の所属グループのみ返す（updated_at desc）" do
            do_request

            expect(response).to have_http_status(:ok)
            assert_response_schema_confirm(200)

            body = response.parsed_body
            expect(body).to be_a(Hash)
            expect(body).to include("groups", "meta")

            groups = body.fetch("groups")
            expect(groups).to be_an(Array)
            expect(groups.size).to eq(2)

            expect(groups[0]["public_id"]).to eq(active_newer_group.public_id)
            expect(groups[1]["public_id"]).to eq(active_older_group.public_id)

            expect(groups[0]).to include(
              "public_id" => active_newer_group.public_id,
              "name" => "新しい",
              "currency" => "JPY"
            )
            expect(groups[0]["updated_at"]).to be_a(String)

            expect(groups[0]["member_count"]).to eq(2)
            expect(groups[1]["member_count"]).to eq(1)

            returned_ids = groups.map { |g| g.fetch("public_id") }
            expect(returned_ids).not_to include(inactive_group.public_id)
            expect(returned_ids).not_to include(other_users_group.public_id)

            meta = body.fetch("meta")
            expect(meta).to be_a(Hash)
            expect(meta.fetch("page")).to eq(1)
            expect(meta.fetch("per_page")).to eq(20)
            expect(meta.fetch("total_count")).to eq(2)
            expect(meta.fetch("total_pages")).to eq(1)
          end
        end

        context "所属グループが0件のとき" do
          it "200 を返し、groups: [] と meta(per_page=20) を返す" do
            do_request

            expect(response).to have_http_status(:ok)
            assert_response_schema_confirm(200)

            body = response.parsed_body
            expect(body).to be_a(Hash)
            expect(body).to include("groups", "meta")
            expect(body.fetch("groups")).to eq([])

            meta = body.fetch("meta")
            expect(meta.fetch("page")).to eq(1)
            expect(meta.fetch("per_page")).to eq(20)
            expect(meta.fetch("total_count")).to eq(0)
            expect(meta.fetch("total_pages")).to eq(0)
          end
        end

        context "ページネーション（CI負荷対策：stub_const で per_page を小さく）" do
          let!(:other_user) { create(:user) }

          before do
            stub_const("Api::V1::GroupsController::PER_PAGE", 3)

            # 5件あれば十分：
            # - page=1 => 3件
            # - page=2 => 2件
            @groups = create_list(:group, 5, currency: "JPY")
            base_time = 2.days.ago

            @groups.each_with_index do |g, i|
              g.update!(updated_at: base_time + i.minutes)

              create(:member, user: user, group: g, active: true, role: "MEMBER", joined_at: Time.current)
              create(:member, user: other_user, group: g, active: true, role: "MEMBER", joined_at: Time.current)
            end
          end

          context "page を指定しないとき" do
            let(:query) { {} }

            it "1ページ目として 3 件返し、meta.per_page も 3 になる" do
              do_request

              expect(response).to have_http_status(:ok)
              assert_response_schema_confirm(200)

              body = response.parsed_body
              expect(body.fetch("groups").size).to eq(3)

              meta = body.fetch("meta")
              expect(meta.fetch("page")).to eq(1)
              expect(meta.fetch("per_page")).to eq(3)
              expect(meta.fetch("total_count")).to eq(5)
              expect(meta.fetch("total_pages")).to eq(2)
            end
          end

          context "page=2 のとき" do
            let(:query) { { page: 2 } }

            it "2ページ目として 2 件返す（offset が効く）" do
              do_request

              expect(response).to have_http_status(:ok)
              assert_response_schema_confirm(200)

              body = response.parsed_body
              expect(body.fetch("groups").size).to eq(2)

              meta = body.fetch("meta")
              expect(meta.fetch("page")).to eq(2)
              expect(meta.fetch("per_page")).to eq(3)
              expect(meta.fetch("total_count")).to eq(5)
              expect(meta.fetch("total_pages")).to eq(2)
            end
          end

          context "page が 0 以下のとき" do
            let(:query) { { page: 0 } }

            it "page は 1 扱いになる" do
              do_request

              expect(response).to have_http_status(:ok)
              assert_response_schema_confirm(200)

              meta = response.parsed_body.fetch("meta")
              expect(meta.fetch("page")).to eq(1)
            end
          end

          context "per_page を指定しても無視する設計のとき" do
            let(:query) { { per_page: 1 } }

            it "返却件数は 3 のまま、meta.per_page も 3 のまま" do
              do_request

              expect(response).to have_http_status(:ok)
              assert_response_schema_confirm(200)

              body = response.parsed_body
              expect(body.fetch("groups").size).to eq(3)

              meta = body.fetch("meta")
              expect(meta.fetch("per_page")).to eq(3)
              expect(meta.fetch("total_count")).to eq(5)
              expect(meta.fetch("total_pages")).to eq(2)
            end
          end
        end
      end

      context "認証失敗（Authorization ヘッダーなし）" do
        let!(:headers) { { "Content-Type" => "application/json" } }

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!)
        end

        it "401 missing_token を返す（Problem Details）" do
          do_request

          expect(response).to have_http_status(:unauthorized)
          expect(response.media_type).to eq("application/problem+json")
          assert_response_schema_confirm(401)

          expect(response.parsed_body).to include(
            "title" => "Unauthorized",
            "status" => 401,
            "reason" => "missing_token"
          )
        end

        it "Clerk::JwtVerifier.verify! を呼ばない" do
          do_request
          expect(Clerk::JwtVerifier).not_to have_received(:verify!)
        end
      end

      context "認証失敗（Authorization: Bearer / verify! 失敗）" do
        let!(:token) { "dummy" }
        let!(:headers) do
          {
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json"
          }
        end

        before do
          allow(Clerk::JwtVerifier).to receive(:verify!)
            .and_raise(Clerk::JwtVerifier::VerificationError.new("decode failed"))
        end

        it "401 invalid_token を返す（Problem Details）" do
          do_request

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
end
