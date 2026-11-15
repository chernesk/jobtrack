require "rails_helper"
require "fugit" # Solid Queue's schedule parser; only auto-loaded in production

RSpec.describe FollowUpReminderJob, type: :job do
  let(:today) { Date.new(2026, 11, 15) }

  # Build records that were saved "yesterday" and so are not flagged yet, the way a
  # follow-up date passing without any edit would leave them.
  def create_unflagged(**attributes)
    create(:opportunity, **attributes).tap { |record| record.update_columns(due: false) }
  end

  it "flags open opportunities whose follow-up date is today or earlier" do
    overdue = create_unflagged(status: "contacted", follow_up_on: today - 4)
    due_today = create_unflagged(status: "interviewing", follow_up_on: today)

    described_class.perform_now(today)

    expect(overdue.reload.due).to be(true)
    expect(due_today.reload.due).to be(true)
  end

  it "leaves future, undated and closed opportunities alone" do
    future = create_unflagged(status: "contacted", follow_up_on: today + 1)
    undated = create_unflagged(status: "talking", follow_up_on: nil)
    closed = create_unflagged(status: "closed", follow_up_on: today - 2)

    described_class.perform_now(today)

    expect([ future, undated, closed ].map { |record| record.reload.due }).to all(be(false))
  end

  it "clears the flag on records that no longer qualify" do
    stale = create(:opportunity, status: "contacted", follow_up_on: today - 1)
    stale.update_columns(due: true, status: "closed") # closed behind the callback's back

    result = described_class.perform_now(today)

    expect(stale.reload.due).to be(false)
    expect(result).to eq(marked: 0, cleared: 1)
  end

  it "reports how many it changed, and changes nothing on a second run" do
    create_unflagged(status: "contacted", follow_up_on: today - 1)

    expect(described_class.perform_now(today)).to eq(marked: 1, cleared: 0)
    expect(described_class.perform_now(today)).to eq(marked: 0, cleared: 0)
  end

  it "uses the current date when none is given" do
    travel_to today do
      due = create_unflagged(status: "talking", follow_up_on: today)

      described_class.perform_now

      expect(due.reload.due).to be(true)
    end
  end

  it "agrees with the scope the rule is defined in" do
    records = [ -3, 0, 2 ].flat_map { |offset| %w[contacted closed].map { |status| create_unflagged(status: status, follow_up_on: today + offset) } }

    described_class.perform_now(today)

    expect(Opportunity.where(due: true)).to match_array(Opportunity.follow_up_due(today))
    expect(records.size).to eq(6)
  end
end

RSpec.describe "Follow-up reminder schedule" do
  let(:entry) { YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "follow_up_reminder") }

  it "runs the job daily at 7am Eastern" do
    expect(entry["class"]).to eq("FollowUpReminderJob")

    cron = Fugit.parse_cron(entry["schedule"])
    expect(cron).not_to be_nil
    next_run = cron.next_time(Time.utc(2026, 11, 15, 13, 0)).to_t # 8am ET on 15 Nov

    expect(next_run.in_time_zone("America/New_York").strftime("%F %H:%M")).to eq("2026-11-16 07:00")
  end
end
