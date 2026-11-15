require "rails_helper"

RSpec.describe "Opportunity form", type: :request do
  let(:inertia) { { "X-Inertia" => "true" } }
  let(:valid_params) { { opportunity: { company: "Northwind Health", role: "Rails Engineer", status: "contacted" } } }

  it "redirects to sign-in when signed out" do
    post opportunities_path, params: valid_params

    expect(response).to redirect_to(new_session_path)
    expect(Opportunity.count).to eq(0)
  end

  context "when signed in" do
    before do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }
    end

    it "renders the new form" do
      get new_opportunity_path, headers: inertia

      expect(response.parsed_body["component"]).to eq("Opportunities/New")
    end

    it "renders the edit form with the record" do
      opportunity = create(:opportunity, company: "Acme Logistics")

      get edit_opportunity_path(opportunity), headers: inertia

      expect(response.parsed_body["component"]).to eq("Opportunities/Edit")
      expect(response.parsed_body["props"]["opportunity"]).to include("id" => opportunity.id, "company" => "Acme Logistics")
    end

    describe "POST /opportunities" do
      it "creates the record and redirects to the list with a notice" do
        expect { post opportunities_path, params: valid_params }.to change(Opportunity, :count).by(1)

        expect(response).to redirect_to(opportunities_path)
        expect(flash[:notice]).to eq("Opportunity added.")
        expect(Opportunity.last).to have_attributes(company: "Northwind Health", status: "contacted")
      end

      it "treats blank selects and numbers as not provided" do
        post opportunities_path, params: { opportunity: valid_params[:opportunity].merge(kind: "", source: "", pay_unit: "", pay_min: "", follow_up_on: "") }

        expect(Opportunity.last).to have_attributes(kind: nil, source: nil, pay_unit: nil, pay_min: nil, follow_up_on: nil)
      end

      it "redirects back to the form with errors keyed by field when invalid" do
        expect {
          post opportunities_path, params: { opportunity: { company: "", role: "", pay_min: "100", pay_max: "50" } }, headers: inertia
        }.not_to change(Opportunity, :count)

        expect(response).to redirect_to(new_opportunity_path)
        follow_redirect!(headers: inertia)
        errors = response.parsed_body["props"]["errors"]
        expect(errors.keys).to contain_exactly("company", "role", "pay_max")
        expect(errors["company"]).to eq("can't be blank")
      end

      it "ignores attributes that are not editable, such as position" do
        post opportunities_path, params: { opportunity: valid_params[:opportunity].merge(position: 99) }

        expect(Opportunity.last.position).to eq(1)
      end

      it "rejects a request with no opportunity key" do
        post opportunities_path, params: {}

        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "PATCH /opportunities/:id" do
      let!(:opportunity) { create(:opportunity, company: "Acme Logistics", role: "Engineer") }

      it "updates the record and redirects to the list" do
        patch opportunity_path(opportunity), params: { opportunity: { company: "Acme Freight", notes: "Called back" } }

        expect(response).to redirect_to(opportunities_path)
        expect(opportunity.reload).to have_attributes(company: "Acme Freight", notes: "Called back", role: "Engineer")
      end

      it "redirects back to the edit form with errors when invalid" do
        patch opportunity_path(opportunity), params: { opportunity: { company: "" } }, headers: inertia

        expect(response).to redirect_to(edit_opportunity_path(opportunity))
        expect(opportunity.reload.company).to eq("Acme Logistics")
      end

      it "returns 404 for an unknown id" do
        patch opportunity_path(0), params: valid_params

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
