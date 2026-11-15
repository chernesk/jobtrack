require "rails_helper"

RSpec.describe "Theme script", type: :request do
  it "is on the sign-in page, so it follows the saved theme before paint" do
    get new_session_path

    expect(response.body).to include('localStorage.getItem("theme")')
    expect(response.body).to include('name="color-scheme"')
  end

  it "is on Inertia pages too" do
    user = create(:user)
    post session_path, params: { email_address: user.email_address, password: "password" }

    get root_path

    expect(response.body).to include('localStorage.getItem("theme")')
  end
end
