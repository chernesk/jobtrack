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

    it "renders the Inertia Home/Index page with the current user" do
      user = create(:user, email_address: "demo@example.com")
      post session_path, params: { email_address: user.email_address, password: "password" }

      get root_path, headers: { "X-Inertia" => "true" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        "component" => "Home/Index",
        "props" => include("user" => { "email_address" => "demo@example.com" })
      )
    end
  end
end
