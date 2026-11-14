require "rails_helper"

RSpec.describe User, type: :model do
  it "normalizes the email address" do
    user = build(:user, email_address: "  Demo@Example.COM ")

    expect(user.email_address).to eq("demo@example.com")
  end

  it "authenticates with the right password only" do
    user = create(:user)

    expect(User.authenticate_by(email_address: user.email_address, password: "password")).to eq(user)
    expect(User.authenticate_by(email_address: user.email_address, password: "nope")).to be_nil
  end
end
