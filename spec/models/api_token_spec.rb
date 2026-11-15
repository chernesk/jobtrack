require "rails_helper"

RSpec.describe ApiToken do
  let(:user) { create(:user) }

  it "issues a token whose plaintext authenticates but is never stored" do
    record, plaintext = described_class.issue(user: user, name: "laptop")

    expect(record.token_digest).not_to include(plaintext)
    expect(described_class.authenticate(plaintext)).to eq(record)
  end

  it "rejects unknown and blank tokens" do
    described_class.issue(user: user, name: "laptop")

    expect(described_class.authenticate("nope")).to be_nil
    expect(described_class.authenticate(nil)).to be_nil
    expect(described_class.authenticate("")).to be_nil
  end

  it "requires a name" do
    expect { described_class.issue(user: user, name: "") }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "records last use at most once an hour" do
    record, = described_class.issue(user: user, name: "laptop")

    record.touch_last_used
    first = record.reload.last_used_at
    expect(first).to be_present

    travel_to(10.minutes.from_now) { record.touch_last_used }
    expect(record.reload.last_used_at).to eq(first)

    travel_to(2.hours.from_now) { record.touch_last_used }
    expect(record.reload.last_used_at).to be > first
  end
end
