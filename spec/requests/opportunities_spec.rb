require "rails_helper"

RSpec.describe "Opportunities", type: :request do
  describe "GET /opportunities" do
    let(:inertia) { { "X-Inertia" => "true" } }

    def props
      response.parsed_body["props"]
    end

    def companies
      props["opportunities"].pluck("company")
    end

    it "redirects to sign-in when signed out" do
      get opportunities_path

      expect(response).to redirect_to(new_session_path)
    end

    context "when signed in" do
      before do
        user = create(:user)
        post session_path, params: { email_address: user.email_address, password: "password" }
      end

      it "renders the Opportunities/Index page with opportunities and the applied filters" do
        create(:opportunity, company: "Acme Logistics", status: "talking", pay_min: 90, pay_max: 110, pay_unit: "hourly")

        get opportunities_path, headers: inertia

        expect(response.parsed_body["component"]).to eq("Opportunities/Index")
        expect(props["filters"]).to eq("q" => "", "status" => "", "kind" => "", "dir" => "asc", "archived" => false)
        expect(props["opportunities"].first).to include(
          "company" => "Acme Logistics", "status" => "talking", "pay_min" => 90, "pay_max" => 110, "pay_unit" => "hourly"
        )
      end

      it "filters by status and kind" do
        create(:opportunity, company: "Match", status: "talking", kind: "contract_w2")
        create(:opportunity, company: "Wrong status", status: "offer", kind: "contract_w2")
        create(:opportunity, company: "Wrong kind", status: "talking", kind: "full_time")

        get opportunities_path, params: { status: "talking", kind: "contract_w2" }, headers: inertia

        expect(companies).to eq([ "Match" ])
        expect(props["filters"]).to include("status" => "talking", "kind" => "contract_w2")
      end

      it "searches company and role" do
        create(:opportunity, company: "Acme Logistics", role: "Rails Engineer")
        create(:opportunity, company: "Globex", role: "Acme Liaison")
        create(:opportunity, company: "Initech", role: "Developer")

        get opportunities_path, params: { q: " acme " }, headers: inertia

        expect(companies).to contain_exactly("Acme Logistics", "Globex")
        expect(props["filters"]["q"]).to eq("acme")
      end

      it "sorts by follow-up date, soonest first by default, with undated last" do
        create(:opportunity, company: "Later", follow_up_on: Date.new(2026, 7, 1))
        create(:opportunity, company: "Undated", follow_up_on: nil)
        create(:opportunity, company: "Sooner", follow_up_on: Date.new(2026, 6, 1))

        get opportunities_path, headers: inertia
        expect(companies).to eq(%w[Sooner Later Undated])

        get opportunities_path, params: { dir: "desc" }, headers: inertia
        expect(companies).to eq(%w[Later Sooner Undated])
        expect(props["filters"]["dir"]).to eq("desc")
      end

      it "ignores unknown filter values and echoes them as blank" do
        create(:opportunity, company: "Acme")

        get opportunities_path, params: { status: "ghosted", kind: "unpaid", dir: "sideways" }, headers: inertia

        expect(companies).to eq([ "Acme" ])
        expect(props["filters"]).to eq("q" => "", "status" => "", "kind" => "", "dir" => "asc", "archived" => false)
      end

      it "does not blow up on tampered (non-string) params" do
        create(:opportunity)

        get "/opportunities?q[a]=1&status[]=talking&dir[x]=y", headers: inertia

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "application details from the form" do
    before do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }
    end

    it "saves the details and treats an empty channel as not chosen" do
      post opportunities_path, params: { opportunity: { company: "A", role: "B", application_channel: "form",
                                                         resume_version: "v3", contact_name: "Dana" } }
      expect(Opportunity.last).to have_attributes(application_channel: "form", resume_version: "v3", contact_name: "Dana")

      patch opportunity_path(Opportunity.last), params: { opportunity: { application_channel: "" } }
      expect(Opportunity.last.application_channel).to be_nil
    end
  end
end
