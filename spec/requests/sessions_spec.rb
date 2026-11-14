require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user) }

  it "signs in with valid credentials" do
    post session_path, params: { email_address: user.email_address, password: "password" }

    expect(response).to redirect_to(root_url)
  end

  it "rejects an invalid password" do
    post session_path, params: { email_address: user.email_address, password: "wrong" }

    expect(response).to redirect_to(new_session_path)
  end
end
