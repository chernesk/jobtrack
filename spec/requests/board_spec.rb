require "rails_helper"

RSpec.describe "Board", type: :request do
  let(:inertia) { { "X-Inertia" => "true" } }

  it "redirects to sign-in when signed out" do
    get board_path
    expect(response).to redirect_to(new_session_path)

    patch move_opportunity_path(create(:opportunity)), params: { status: "talking", index: 0 }
    expect(response).to redirect_to(new_session_path)
  end

  context "when signed in" do
    before do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }
    end

    it "renders every opportunity, ordered by position" do
      second = create(:opportunity, company: "Second", status: "talking")
      first = create(:opportunity, company: "First", status: "talking")
      first.move_to("talking", 0)

      get board_path, headers: inertia

      expect(response.parsed_body["component"]).to eq("Board/Show")
      expect(response.parsed_body["props"]["opportunities"].pluck("id")).to eq([ first.id, second.id ])
    end

    describe "PATCH /opportunities/:id/move" do
      let!(:card) { create(:opportunity, status: "contacted") }
      let!(:other) { create(:opportunity, status: "talking") }

      it "moves the card and redirects back to the board" do
        patch move_opportunity_path(card), params: { status: "talking", index: 0 }

        expect(response).to redirect_to(board_path)
        expect(card.reload).to have_attributes(status: "talking", position: 1)
        expect(other.reload.position).to eq(2)
      end

      it "returns a status error and changes nothing for an unknown status" do
        patch move_opportunity_path(card), params: { status: "archived", index: 0 }, headers: inertia

        expect(response).to redirect_to(board_path)
        follow_redirect!(headers: inertia)
        expect(response.parsed_body["props"]["errors"]).to eq("status" => "is not a valid status")
        expect(card.reload.status).to eq("contacted")
      end

      it "rejects a request missing its parameters" do
        patch move_opportunity_path(card), params: { status: "talking" }

        expect(response).to have_http_status(:bad_request)
      end

      it "returns 404 for an unknown card" do
        patch move_opportunity_path(0), params: { status: "talking", index: 0 }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
