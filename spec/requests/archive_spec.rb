require "rails_helper"

RSpec.describe "Archiving", type: :request do
  let(:inertia) { { "X-Inertia" => "true" } }
  let!(:keep) { create(:opportunity, company: "Keep Co", status: "talking") }
  let!(:mistake) { create(:opportunity, company: "Mistake Co", status: "talking") }

  it "requires sign-in" do
    patch archive_opportunity_path(mistake)

    expect(response).to redirect_to(new_session_path)
    expect(mistake.reload).not_to be_archived
  end

  context "when signed in" do
    before do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }
    end

    it "archives, then hides the record from the board, list and dashboard counts" do
      patch archive_opportunity_path(mistake)
      expect(response).to redirect_to(opportunities_path)

      get board_path, headers: inertia
      expect(response.parsed_body["props"]["opportunities"].pluck("company")).to eq([ "Keep Co" ])

      get opportunities_path, headers: inertia
      expect(response.parsed_body["props"]["opportunities"].pluck("company")).to eq([ "Keep Co" ])

      get root_path, headers: inertia
      expect(response.parsed_body["props"]["counts"]["talking"]).to eq(1)
    end

    it "lists only archived records with ?archived=1, and echoes the filter" do
      mistake.archive!

      get opportunities_path(archived: 1), headers: inertia

      props = response.parsed_body["props"]
      expect(props["opportunities"].pluck("company")).to eq([ "Mistake Co" ])
      expect(props["filters"]["archived"]).to be(true)
    end

    it "restores a record to the board" do
      mistake.archive!

      patch restore_opportunity_path(mistake)

      expect(response).to redirect_to(opportunity_path(mistake))
      expect(mistake.reload).not_to be_archived
    end

    it "still opens an archived record directly" do
      mistake.archive!

      get opportunity_path(mistake), headers: inertia

      expect(response.parsed_body["props"]["opportunity"]["archived_at"]).to be_present
    end

    it "saves a closed reason from the form" do
      patch opportunity_path(keep), params: { opportunity: { status: "closed", closed_reason: "rejected" } }

      expect(keep.reload).to have_attributes(status: "closed", closed_reason: "rejected")
    end
  end
end
