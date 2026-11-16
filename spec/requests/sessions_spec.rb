require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user) }

  it "renders a sign-in form with labelled fields" do
    get new_session_path

    expect(response.body).to include('for="email_address"', 'for="password"', "Sign in", "Forgot password?")
  end

  it "shows the error on the sign-in page after a bad password" do
    post session_path, params: { email_address: user.email_address, password: "wrong" }
    follow_redirect!

    expect(response.body).to include('role="alert"', "Try another email address or password.")
  end

  it "signs in with valid credentials" do
    post session_path, params: { email_address: user.email_address, password: "password" }

    expect(response).to redirect_to(root_url)
  end

  it "rejects an invalid password" do
    post session_path, params: { email_address: user.email_address, password: "wrong" }

    expect(response).to redirect_to(new_session_path)
  end

  describe "DELETE /session" do
    before { post session_path, params: { email_address: user.email_address, password: "password" } }

    it "ends the session and redirects a normal request to sign-in" do
      delete session_path

      expect(response).to redirect_to(new_session_path)
      get root_path
      expect(response).to redirect_to(new_session_path)
    end

    it "tells an Inertia client to do a full page visit to sign-in" do
      delete session_path, headers: { "X-Inertia" => "true" }

      expect(response).to have_http_status(:conflict)
      expect(response.headers["X-Inertia-Location"]).to eq(new_session_path)
    end
  end
end
