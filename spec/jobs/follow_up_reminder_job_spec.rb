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

RSpec.describe FollowUpReminderJob, "notifications", type: :job do
  let(:today) { Date.new(2026, 11, 15) }

  before { allow(NtfyClient).to receive(:publish).and_return(true) }

  around do |example|
    saved = ENV.to_h.slice("APP_URL", "NTFY_HIDE_NAMES")
    ENV.delete("APP_URL")
    ENV.delete("NTFY_HIDE_NAMES")
    example.run
    ENV.delete("APP_URL")
    ENV.delete("NTFY_HIDE_NAMES")
    saved.each { |key, value| ENV[key] = value }
  end

  it "sends one notification listing what is due, overdue first, with a high priority when something is overdue" do
    create(:opportunity, company: "Globex", role: "Dev", status: "contacted", follow_up_on: today)
    create(:opportunity, company: "Acme", role: "Engineer", status: "applied", follow_up_on: today - 3)

    described_class.perform_now(today)

    expect(NtfyClient).to have_received(:publish).once.with(
      title: "2 follow-ups due",
      message: "Acme, Engineer (3 days overdue)\nGlobex, Dev (due today)",
      click: nil,
      tags: "bell",
      priority: 4
    )
  end

  it "uses the normal priority and singular wording when one thing is due today" do
    create(:opportunity, company: "Globex", role: "Dev", status: "contacted", follow_up_on: today)

    described_class.perform_now(today)

    expect(NtfyClient).to have_received(:publish).with(hash_including(title: "1 follow-up due", priority: 3))
  end

  it "sends nothing when nothing is due" do
    create(:opportunity, status: "contacted", follow_up_on: today + 2)
    create(:opportunity, status: "closed", follow_up_on: today - 2)

    described_class.perform_now(today)

    expect(NtfyClient).not_to have_received(:publish)
  end

  it "caps the list and says how many more there are" do
    10.times { |n| create(:opportunity, company: "Co #{n}", status: "contacted", follow_up_on: today - n - 1) }

    described_class.perform_now(today)

    expect(NtfyClient).to have_received(:publish).with(hash_including(title: "10 follow-ups due")) do |args|
      expect(args[:message].lines.size).to eq(9)
      expect(args[:message]).to end_with("and 2 more")
    end
  end

  it "sends no names when NTFY_HIDE_NAMES is set" do
    ENV["NTFY_HIDE_NAMES"] = "1"
    create(:opportunity, company: "Secret Corp", status: "contacted", follow_up_on: today)

    described_class.perform_now(today)

    expect(NtfyClient).to have_received(:publish) do |args|
      expect(args[:message]).not_to include("Secret Corp")
    end
  end

  it "links to the app when APP_URL is set" do
    ENV["APP_URL"] = "http://nas.local:3200"
    create(:opportunity, status: "contacted", follow_up_on: today)

    described_class.perform_now(today)

    expect(NtfyClient).to have_received(:publish).with(hash_including(click: "http://nas.local:3200"))
  end

  it "still updates the flags when sending fails" do
    allow(NtfyClient).to receive(:publish).and_return(false)
    record = create(:opportunity, status: "contacted", follow_up_on: today - 1)
    record.update_columns(due: false)

    expect(described_class.perform_now(today)).to eq(marked: 1, cleared: 0)
    expect(record.reload.due).to be(true)
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
