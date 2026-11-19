require "rails_helper"

# Changing a status from the edit form or the JSON API (not by dragging) must put the card
# at the bottom of its new column, not leave it with its old column's number.
RSpec.describe "Status changes and column order", type: :request do
  def column(status)
    Opportunity.active.where(status: status).order(:position, :id).pluck(:company, :position)
  end

  let!(:mover) { create(:opportunity, company: "Mover", status: "contacted") }

  before do
    create(:opportunity, company: "Applied A", status: "applied")
    create(:opportunity, company: "Applied B", status: "applied")
  end

  it "from the edit form" do
    user = create(:user)
    post session_path, params: { email_address: user.email_address, password: "password" }

    patch opportunity_path(mover), params: { opportunity: { status: "applied" } }

    expect(column("applied")).to eq([ [ "Applied A", 1 ], [ "Applied B", 2 ], [ "Mover", 3 ] ])
  end

  it "from the JSON API" do
    token = ApiToken.issue(user: create(:user), name: "test").last

    patch api_v1_opportunity_path(mover), params: { opportunity: { status: "applied" } }.to_json,
      headers: { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(column("applied")).to eq([ [ "Applied A", 1 ], [ "Applied B", 2 ], [ "Mover", 3 ] ])
  end
end
