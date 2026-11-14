require "rails_helper"

RSpec.describe Activity, type: :model do
  it "has a valid factory" do
    expect(build(:activity)).to be_valid
  end

  it "requires occurred_on and body" do
    activity = build(:activity, occurred_on: nil, body: "")

    expect(activity).not_to be_valid
    expect(activity.errors[:occurred_on]).to be_present
    expect(activity.errors[:body]).to be_present
  end

  it "requires an opportunity" do
    expect(build(:activity, opportunity: nil)).not_to be_valid
  end

  it "supports the brief's kinds only" do
    expect(described_class.kinds.keys).to eq(%w[email call interview note])
    expect(build(:activity, kind: "carrier_pigeon")).not_to be_valid
  end
end
