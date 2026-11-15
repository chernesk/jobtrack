require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "redirects to sign-in when signed out" do
      get root_path

      expect(response).to redirect_to(new_session_path)
    end

    it "renders the full HTML page with the Inertia mount point and Vite entrypoint" do
      user = create(:user)
      post session_path, params: { email_address: user.email_address, password: "password" }

      get root_path

      expect(response.body).to include('id="app"', "inertia")
      # The v3 client reads the initial page from a script element, not a div attribute.
      expect(response.body).to include('<script data-page="app" type="application/json">')
    end

    context "when signed in" do
      before do
        user = create(:user)
        post session_path, params: { email_address: user.email_address, password: "password" }
      end

      def props
        get root_path, headers: { "X-Inertia" => "true" }
        response.parsed_body["props"]
      end

      it "renders Home/Index with zeroed counts when there is no data" do
        get root_path, headers: { "X-Inertia" => "true" }

        expect(response.parsed_body["component"]).to eq("Home/Index")
        expect(props).to include("follow_ups_due" => [], "recent_activity" => [])
        expect(props["counts"]).to eq(Opportunity::STATUSES.index_with { 0 })
      end

      it "sends today's date from the server's time zone" do
        travel_to Time.utc(2026, 11, 16, 2, 0) do # 9pm the previous evening in New York
          expect(props["today"]).to eq("2026-11-15")
        end
      end

      it "counts opportunities by status" do
        create_list(:opportunity, 2, status: "talking")
        create(:opportunity, status: "offer")

        expect(props["counts"]).to include("talking" => 2, "offer" => 1, "closed" => 0)
      end

      it "lists open follow-ups due today or earlier, most overdue first" do
        travel_to Date.new(2026, 11, 15) do
          create(:opportunity, company: "Later", status: "contacted", follow_up_on: Date.new(2026, 11, 20))
          create(:opportunity, company: "Today", status: "talking", follow_up_on: Date.new(2026, 11, 15))
          create(:opportunity, company: "Overdue", status: "contacted", follow_up_on: Date.new(2026, 11, 10))
          create(:opportunity, company: "Closed", status: "closed", follow_up_on: Date.new(2026, 11, 1))
          create(:opportunity, company: "No date", status: "contacted", follow_up_on: nil)

          expect(props["follow_ups_due"].pluck("company")).to eq(%w[Overdue Today])
        end
      end

      it "shows the most recent activity first, with its company, capped at eight" do
        opportunity = create(:opportunity, company: "Acme Logistics")
        10.times { |n| create(:activity, opportunity: opportunity, occurred_on: Date.new(2026, 11, 1) + n, body: "Entry #{n}") }

        feed = props["recent_activity"]

        expect(feed.size).to eq(8)
        expect(feed.first).to include("body" => "Entry 9", "opportunity" => { "id" => opportunity.id, "company" => "Acme Logistics" })
        expect(feed.pluck("body")).to eq((2..9).map { |n| "Entry #{n}" }.reverse)
      end
    end

    it "shares the signed-in user and an empty flash with every page" do
      user = create(:user, email_address: "demo@example.com")
      post session_path, params: { email_address: user.email_address, password: "password" }

      get root_path, headers: { "X-Inertia" => "true" }

      expect(response.parsed_body["props"]).to include(
        "auth" => { "user" => { "email_address" => "demo@example.com" } },
        "flash" => {}
      )
    end
  end
end
