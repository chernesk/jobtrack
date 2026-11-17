require "rails_helper"

RSpec.describe "JSON API: opportunities", type: :request do
  let(:user) { create(:user) }
  let(:plaintext) { ApiToken.issue(user: user, name: "test").last }
  let(:auth) { { "Authorization" => "Bearer #{plaintext}" } }
  let(:json) { response.parsed_body }

  describe "authentication" do
    it "rejects a missing token" do
      get api_v1_opportunities_path

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["WWW-Authenticate"]).to start_with("Bearer")
      expect(json["error"]).to be_present
    end

    it "rejects a wrong token" do
      get api_v1_opportunities_path, headers: { "Authorization" => "Bearer wrong" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not accept a browser session cookie" do
      post session_path, params: { email_address: user.email_address, password: "password" }
      get api_v1_opportunities_path

      expect(response).to have_http_status(:unauthorized)
    end

    it "protects every endpoint" do
      opportunity = create(:opportunity)

      post api_v1_opportunities_path, params: { opportunity: { company: "X", role: "Y" } }, as: :json
      expect(response).to have_http_status(:unauthorized)
      patch api_v1_opportunity_path(opportunity), params: { opportunity: { company: "X" } }, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(opportunity.reload.company).not_to eq("X")
      expect(Opportunity.count).to eq(1)
    end
  end

  describe "GET /api/v1/opportunities" do
    it "lists opportunities as JSON" do
      create(:opportunity, company: "Northwind Health", follow_up_on: Date.new(2026, 12, 1))

      get api_v1_opportunities_path, headers: auth

      expect(response).to have_http_status(:ok)
      expect(json["opportunities"].map { |o| o["company"] }).to eq([ "Northwind Health" ])
      expect(json["opportunities"].first).to include("id", "status", "follow_up_on" => "2026-12-01")
    end

    it "filters by search, status and kind" do
      create(:opportunity, company: "Northwind Health", status: "talking", kind: "full_time")
      create(:opportunity, company: "Acme Logistics", status: "talking", kind: "contract_w2")
      create(:opportunity, company: "Northwind Labs", status: "offer", kind: "full_time")

      get api_v1_opportunities_path, params: { q: "north", status: "talking", kind: "full_time" }, headers: auth

      expect(json["opportunities"].map { |o| o["company"] }).to eq([ "Northwind Health" ])
    end
  end

  describe "GET /api/v1/opportunities/:id" do
    it "returns one opportunity" do
      opportunity = create(:opportunity, company: "Acme Logistics")

      get api_v1_opportunity_path(opportunity), headers: auth

      expect(json["opportunity"]).to include("id" => opportunity.id, "company" => "Acme Logistics")
    end

    it "returns 404 JSON for a missing id" do
      get api_v1_opportunity_path(0), headers: auth

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to eq("Not found")
    end
  end

  describe "POST /api/v1/opportunities" do
    it "creates an opportunity" do
      post api_v1_opportunities_path, params: { opportunity: { company: "Northwind Health", role: "Rails Engineer", status: "contacted" } },
        headers: auth, as: :json

      expect(response).to have_http_status(:created)
      expect(response.headers["Location"]).to eq(api_v1_opportunity_url(Opportunity.last))
      expect(json["opportunity"]).to include("company" => "Northwind Health", "status" => "contacted")
    end

    it "returns validation errors with 422 and creates nothing" do
      post api_v1_opportunities_path, params: { opportunity: { company: "", role: "", status: "bogus", pay_min: 10, pay_max: 5 } },
        headers: auth, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"].keys).to include("company", "role", "status", "pay_max")
      expect(Opportunity.count).to eq(0)
    end

    it "treats blank optional enums as not chosen" do
      post api_v1_opportunities_path, params: { opportunity: { company: "A", role: "B", kind: "", source: "" } }, headers: auth, as: :json

      expect(json["opportunity"]).to include("kind" => nil, "source" => nil)
    end

    it "returns 400 when the body has no opportunity" do
      post api_v1_opportunities_path, params: {}, headers: auth, as: :json

      expect(response).to have_http_status(:bad_request)
    end

    it "ignores attributes that aren't editable, such as position" do
      post api_v1_opportunities_path, params: { opportunity: { company: "A", role: "B", position: 99, due: true } }, headers: auth, as: :json

      expect(response).to have_http_status(:created)
      expect(Opportunity.last.position).to eq(1)
    end
  end

  describe "PATCH /api/v1/opportunities/:id" do
    it "updates the given fields only" do
      opportunity = create(:opportunity, company: "Acme Logistics", role: "Engineer")

      patch api_v1_opportunity_path(opportunity), params: { opportunity: { status: "interviewing" } }, headers: auth, as: :json

      expect(response).to have_http_status(:ok)
      expect(opportunity.reload).to have_attributes(status: "interviewing", company: "Acme Logistics", role: "Engineer")
    end

    it "returns 422 for invalid data and leaves the record alone" do
      opportunity = create(:opportunity, company: "Acme Logistics")

      patch api_v1_opportunity_path(opportunity), params: { opportunity: { company: "" } }, headers: auth, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to have_key("company")
      expect(opportunity.reload.company).to eq("Acme Logistics")
    end
  end

  describe "archived records" do
    it "leaves them out of the list unless ?archived=true" do
      create(:opportunity, company: "Live Co")
      create(:opportunity, company: "Gone Co").archive!

      get api_v1_opportunities_path, headers: auth
      expect(response.parsed_body["opportunities"].pluck("company")).to eq([ "Live Co" ])

      get api_v1_opportunities_path(archived: "true"), headers: auth
      expect(response.parsed_body["opportunities"].pluck("company")).to contain_exactly("Live Co", "Gone Co")
    end
  end
end
