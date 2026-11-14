require "rails_helper"

RSpec.describe "db/seeds.rb" do
  def run_seeds
    load Rails.root.join("db/seeds.rb")
  end

  it "creates fictional opportunities covering every status, each with 1-4 activities" do
    run_seeds

    expect(Opportunity.count).to be_between(14, 16)
    expect(Opportunity.distinct.pluck(:status)).to match_array(Opportunity.statuses.keys)
    expect(Opportunity.includes(:activities).map { |o| o.activities.size }).to all(be_between(1, 4))
    expect(Opportunity.where.not(follow_up_on: nil).where(follow_up_on: ..Date.current)).to exist
  end

  it "is safe to run twice" do
    run_seeds

    expect { run_seeds }.not_to change { [ User.count, Opportunity.count, Activity.count ] }
  end

  it "only uses example.com URLs" do
    run_seeds

    expect(Opportunity.pluck(:url)).to all(start_with("https://example.com/"))
  end
end
