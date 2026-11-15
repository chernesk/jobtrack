require "rails_helper"

RSpec.describe "Opportunity detail and activities", type: :request do
  let(:inertia) { { "X-Inertia" => "true" } }
  let!(:opportunity) { create(:opportunity, company: "Acme Logistics") }

  it "redirects to sign-in when signed out" do
    get opportunity_path(opportunity)
    expect(response).to redirect_to(new_session_path)

    post opportunity_activities_path(opportunity), params: { activity: { kind: "note", occurred_on: "2026-11-01", body: "x" } }
    expect(response).to redirect_to(new_session_path)
    expect(Activity.count).to eq(0)
  end

  context "when signed in" do
    before do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }
    end

    describe "GET /opportunities/:id" do
      it "renders the opportunity with its activities, newest first" do
        create(:activity, opportunity: opportunity, occurred_on: "2026-11-01", body: "Older")
        create(:activity, opportunity: opportunity, occurred_on: "2026-11-05", body: "Newer")
        other = create(:opportunity)
        create(:activity, opportunity: other, body: "Someone else's")

        get opportunity_path(opportunity), headers: inertia

        expect(response.parsed_body["component"]).to eq("Opportunities/Show")
        props = response.parsed_body["props"]
        expect(props["opportunity"]).to include("id" => opportunity.id, "company" => "Acme Logistics")
        expect(props["activities"].pluck("body")).to eq(%w[Newer Older])
        expect(props["activities"].first.keys).to contain_exactly("id", "kind", "occurred_on", "body")
      end

      it "returns 404 for an unknown id" do
        get opportunity_path(0), headers: inertia

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /opportunities/:id/activities" do
      let(:params) { { activity: { kind: "call", occurred_on: "2026-11-10", body: "Intro call" } } }

      it "adds the activity and returns to the detail page" do
        expect { post opportunity_activities_path(opportunity), params: params }.to change { opportunity.activities.count }.by(1)

        expect(response).to redirect_to(opportunity_path(opportunity))
        expect(flash[:notice]).to eq("Activity added.")
        expect(opportunity.activities.last).to have_attributes(kind: "call", body: "Intro call", occurred_on: Date.new(2026, 11, 10))
      end

      it "returns per-field errors when invalid" do
        expect {
          post opportunity_activities_path(opportunity), params: { activity: { kind: "note", occurred_on: "", body: "" } }, headers: inertia
        }.not_to change(Activity, :count)

        expect(response).to redirect_to(opportunity_path(opportunity))
        follow_redirect!(headers: inertia)
        expect(response.parsed_body["props"]["errors"].keys).to contain_exactly("occurred_on", "body")
      end

      it "reports an unknown kind as a field error instead of raising" do
        post opportunity_activities_path(opportunity), params: { activity: params[:activity].merge(kind: "carrier_pigeon") }, headers: inertia

        expect(response).to redirect_to(opportunity_path(opportunity))
        expect(Activity.count).to eq(0)
      end

      it "returns 404 for an unknown opportunity" do
        post opportunity_activities_path(0), params: params

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
