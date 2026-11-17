require "rails_helper"

RSpec.describe Opportunity, type: :model do
  it "has a valid factory" do
    expect(build(:opportunity)).to be_valid
  end

  describe "validations" do
    it "requires company and role" do
      opportunity = build(:opportunity, company: nil, role: "")

      expect(opportunity).not_to be_valid
      expect(opportunity.errors[:company]).to be_present
      expect(opportunity.errors[:role]).to be_present
    end

    it "allows pay_max equal to or above pay_min" do
      expect(build(:opportunity, pay_min: 100, pay_max: 100)).to be_valid
      expect(build(:opportunity, pay_min: 100, pay_max: 120)).to be_valid
    end

    it "rejects pay_max below pay_min" do
      opportunity = build(:opportunity, pay_min: 120, pay_max: 100)

      expect(opportunity).not_to be_valid
      expect(opportunity.errors[:pay_max]).to be_present
    end

    it "allows a single pay bound" do
      expect(build(:opportunity, pay_min: 100, pay_max: nil)).to be_valid
      expect(build(:opportunity, pay_min: nil, pay_max: 100)).to be_valid
    end

    it "rejects negative pay" do
      expect(build(:opportunity, pay_min: -1)).not_to be_valid
    end

    it "rejects follow_up_on before contacted_on" do
      opportunity = build(:opportunity, contacted_on: Date.new(2026, 5, 10), follow_up_on: Date.new(2026, 5, 9))

      expect(opportunity).not_to be_valid
      expect(opportunity.errors[:follow_up_on]).to be_present
    end

    it "allows follow_up_on on or after contacted_on, or either one alone" do
      expect(build(:opportunity, contacted_on: Date.new(2026, 5, 10), follow_up_on: Date.new(2026, 5, 10))).to be_valid
      expect(build(:opportunity, contacted_on: nil, follow_up_on: Date.new(2026, 5, 10))).to be_valid
      expect(build(:opportunity, contacted_on: Date.new(2026, 5, 10), follow_up_on: nil)).to be_valid
    end
  end

  describe "enums" do
    it "defaults status to not_contacted" do
      expect(described_class.new.status).to eq("not_contacted")
    end

    it "exposes every status from the brief in board order" do
      expect(described_class.statuses.keys).to eq(%w[recommended not_contacted contacted applied talking interviewing offer closed])
    end

    it "rejects unknown enum values" do
      expect(build(:opportunity, status: "ghosted")).not_to be_valid
      expect(build(:opportunity, kind: "unpaid")).not_to be_valid
      expect(build(:opportunity, source: "billboard")).not_to be_valid
      expect(build(:opportunity, pay_unit: "weekly")).not_to be_valid
    end

    it "allows kind and source to be blank" do
      expect(build(:opportunity, kind: nil, source: nil)).to be_valid
    end
  end

  describe "position" do
    it "places new records at the end of their status column" do
      first = create(:opportunity, status: "talking")
      second = create(:opportunity, status: "talking")
      other = create(:opportunity, status: "offer")

      expect([ first.position, second.position, other.position ]).to eq([ 1, 2, 1 ])
    end

    it "keeps an explicit position" do
      expect(create(:opportunity, position: 7).position).to eq(7)
    end
  end

  it "destroys its activities with it" do
    opportunity = create(:opportunity)
    create_list(:activity, 2, opportunity: opportunity)

    expect { opportunity.destroy }.to change(Activity, :count).by(-2)
  end

  describe "index scopes" do
    describe ".with_status / .with_kind" do
      it "filters by a valid value" do
        talking = create(:opportunity, status: "talking", kind: "contract_w2")
        create(:opportunity, status: "offer", kind: "full_time")

        expect(described_class.with_status("talking")).to contain_exactly(talking)
        expect(described_class.with_kind("contract_w2")).to contain_exactly(talking)
      end

      it "ignores blank or unknown values instead of raising or hiding everything" do
        records = create_list(:opportunity, 2)

        expect(described_class.with_status("")).to match_array(records)
        expect(described_class.with_status("ghosted")).to match_array(records)
        expect(described_class.with_kind(nil)).to match_array(records)
        expect(described_class.with_kind("unpaid")).to match_array(records)
      end
    end

    describe ".search" do
      let!(:acme) { create(:opportunity, company: "Acme Logistics", role: "Rails Engineer") }
      let!(:northwind) { create(:opportunity, company: "Northwind Health", role: "Staff Engineer at Acme Labs") }
      let!(:other) { create(:opportunity, company: "Globex", role: "Backend Developer") }

      it "matches company or role, case-insensitively" do
        expect(described_class.search("acme")).to contain_exactly(acme, northwind)
        expect(described_class.search("BACKEND")).to contain_exactly(other)
      end

      it "returns everything for a blank query" do
        expect(described_class.search("  ")).to match_array([ acme, northwind, other ])
        expect(described_class.search(nil)).to match_array([ acme, northwind, other ])
      end

      it "treats % and _ literally rather than as wildcards" do
        expect(described_class.search("%")).to be_empty
        expect(described_class.search("A_me")).to be_empty
      end
    end

    describe ".by_follow_up" do
      let!(:later) { create(:opportunity, company: "B", follow_up_on: Date.new(2026, 6, 20)) }
      let!(:sooner) { create(:opportunity, company: "C", follow_up_on: Date.new(2026, 6, 10)) }
      let!(:undated) { create(:opportunity, company: "A", follow_up_on: nil) }

      it "sorts soonest first and puts undated records last" do
        expect(described_class.by_follow_up).to eq([ sooner, later, undated ])
      end

      it "sorts latest first and still puts undated records last when descending" do
        expect(described_class.by_follow_up(:desc)).to eq([ later, sooner, undated ])
      end
    end
  end

  describe "#as_props" do
    it "includes only the attributes the front end expects, with dates as ISO strings" do
      opportunity = create(:opportunity, follow_up_on: Date.new(2026, 6, 10))

      props = opportunity.as_props

      expect(props.keys).to match_array(Opportunity::PROP_ATTRIBUTES)
      expect(props["follow_up_on"]).to eq("2026-06-10")
      expect(props).not_to include("created_at", "updated_at")
    end
  end
end

RSpec.describe Opportunity, "#move_to", type: :model do
  def column(status)
    Opportunity.where(status: status).order(:position).pluck(:company)
  end

  let!(:a) { create(:opportunity, company: "A", status: "contacted") }
  let!(:b) { create(:opportunity, company: "B", status: "contacted") }
  let!(:c) { create(:opportunity, company: "C", status: "contacted") }
  let!(:x) { create(:opportunity, company: "X", status: "talking") }

  it "reorders within a column" do
    expect(a.move_to("contacted", 2)).to be(true)

    expect(column("contacted")).to eq(%w[B C A])
    expect(Opportunity.where(status: "contacted").order(:position).pluck(:position)).to eq([ 1, 2, 3 ])
  end

  it "moves up within a column" do
    c.move_to("contacted", 0)

    expect(column("contacted")).to eq(%w[C A B])
  end

  it "moves to another column at a position, closing the gap in the old one" do
    b.move_to("talking", 0)

    expect(column("talking")).to eq(%w[B X])
    expect(b.reload.status).to eq("talking")
    expect(column("contacted")).to eq(%w[A C])
    expect(Opportunity.where(status: "contacted").order(:position).pluck(:position)).to eq([ 1, 2 ])
  end

  it "moves into an empty column" do
    a.move_to("offer", 0)

    expect(column("offer")).to eq(%w[A])
    expect(a.reload.position).to eq(1)
  end

  it "clamps an out-of-range index to the ends" do
    a.move_to("talking", 99)
    expect(column("talking")).to eq(%w[X A])

    c.move_to("talking", -5)
    expect(column("talking")).to eq(%w[C X A])
  end

  it "rejects an unknown status and changes nothing" do
    expect(a.move_to("archived", 0)).to be(false)

    expect(a.errors[:status]).to be_present
    expect(a.reload.status).to eq("contacted")
    expect(column("contacted")).to eq(%w[A B C])
  end
end

RSpec.describe Opportunity, ".follow_up_due", type: :model do
  let(:today) { Date.new(2026, 11, 15) }

  it "includes open opportunities due today or earlier and excludes closed, future and undated ones" do
    overdue = create(:opportunity, status: "contacted", follow_up_on: today - 3)
    due_today = create(:opportunity, status: "interviewing", follow_up_on: today)
    create(:opportunity, status: "contacted", follow_up_on: today + 1)
    create(:opportunity, status: "closed", follow_up_on: today - 3)
    create(:opportunity, status: "talking", follow_up_on: nil)

    expect(described_class.follow_up_due(today)).to eq([ overdue, due_today ])
  end

  it "defaults to the current date" do
    travel_to today do
      due = create(:opportunity, status: "talking", follow_up_on: today)

      expect(described_class.follow_up_due).to eq([ due ])
    end
  end
end

RSpec.describe Opportunity, "due flag", type: :model do
  let(:today) { Date.new(2026, 11, 15) }

  around { |example| travel_to(today) { example.run } }

  it "is set on save when an open opportunity is due, and cleared when it is not" do
    record = create(:opportunity, status: "contacted", follow_up_on: today - 1)
    expect(record.due).to be(true)

    record.update!(follow_up_on: today + 7)
    expect(record.due).to be(false)

    record.update!(follow_up_on: today)
    expect(record.due).to be(true)

    record.update!(status: "closed")
    expect(record.due).to be(false)
  end

  it "is never set without a follow-up date" do
    expect(create(:opportunity, status: "talking", follow_up_on: nil).due).to be(false)
  end

  it "is cleared when a card is moved to closed on the board" do
    record = create(:opportunity, status: "talking", follow_up_on: today)

    record.move_to("closed", 0)

    expect(record.reload.due).to be(false)
  end

  it "is flagged by .flagged_due, most overdue first" do
    later = create(:opportunity, status: "talking", follow_up_on: today)
    earlier = create(:opportunity, status: "contacted", follow_up_on: today - 5)
    create(:opportunity, status: "contacted", follow_up_on: today + 1)

    expect(described_class.flagged_due).to eq([ earlier, later ])
  end
end

RSpec.describe Opportunity, "closed reason", type: :model do
  it "is kept while the status is closed" do
    opportunity = create(:opportunity, status: "closed", closed_reason: "rejected")

    expect(opportunity.reload.closed_reason).to eq("rejected")
  end

  it "is forgotten when the opportunity is reopened" do
    opportunity = create(:opportunity, status: "closed", closed_reason: "withdrew")

    opportunity.update!(status: "talking")

    expect(opportunity.reload.closed_reason).to be_nil
  end

  it "is dropped if given for an open opportunity" do
    expect(create(:opportunity, status: "applied", closed_reason: "rejected").closed_reason).to be_nil
  end

  it "rejects an unknown reason" do
    expect(build(:opportunity, status: "closed", closed_reason: "ghosted")).not_to be_valid
  end
end

RSpec.describe Opportunity, "archiving", type: :model do
  it "hides the record from .active and shows it in .archived" do
    keep = create(:opportunity)
    gone = create(:opportunity)

    gone.archive!

    expect(described_class.active).to contain_exactly(keep)
    expect(described_class.archived).to contain_exactly(gone)
    expect(gone).to be_archived
  end

  it "closes the gap in its column" do
    first = create(:opportunity, status: "talking")
    middle = create(:opportunity, status: "talking")
    last = create(:opportunity, status: "talking")

    middle.archive!

    expect([ first.reload.position, last.reload.position ]).to eq([ 1, 2 ])
  end

  it "keeps archived cards out of reminders and the due flag" do
    opportunity = create(:opportunity, status: "contacted", follow_up_on: Date.current - 1)
    expect(opportunity.reload.due).to be(true)

    opportunity.archive!

    expect(opportunity.reload.due).to be(false)
    expect(described_class.follow_up_due).to be_empty
    expect(described_class.flagged_due).to be_empty
  end

  it "restores to the bottom of its column" do
    gone = create(:opportunity, status: "talking")
    other = create(:opportunity, status: "talking")
    gone.archive!

    gone.unarchive!

    expect(gone.reload).not_to be_archived
    expect(gone.position).to be > other.reload.position
  end

  it "does nothing when archived or restored twice" do
    opportunity = create(:opportunity)

    expect(opportunity.unarchive!).to be(true)
    opportunity.archive!
    stamp = opportunity.archived_at
    opportunity.archive!

    expect(opportunity.reload.archived_at).to eq(stamp)
  end
end

RSpec.describe Opportunity, "duplicate detection", type: :model do
  it "trims the external id and treats blank as none" do
    expect(create(:opportunity, external_id: "  42472 ").external_id).to eq("42472")
    expect(create(:opportunity, external_id: "  ").external_id).to be_nil
  end

  it "allows many records without an id, but not a repeated id" do
    create(:opportunity, external_id: nil)

    expect(build(:opportunity, external_id: nil)).to be_valid
    create(:opportunity, external_id: "42472")
    expect(build(:opportunity, external_id: "42472")).not_to be_valid
  end

  it "finds a duplicate by external id, including archived records" do
    kept = create(:opportunity, external_id: "42472")
    kept.archive!

    expect(described_class.find_duplicate(external_id: "42472")).to eq(kept)
    expect(described_class.find_duplicate(external_id: "99999")).to be_nil
  end

  it "finds a duplicate by URL, ignoring host case, a trailing slash and a fragment" do
    kept = create(:opportunity, url: "https://Jobs.Example.com/postings/42472")

    expect(described_class.find_duplicate(url: "https://jobs.example.com/postings/42472/")).to eq(kept)
    expect(described_class.find_duplicate(url: "https://jobs.example.com/postings/42472#apply")).to eq(kept)
    expect(described_class.find_duplicate(url: "https://jobs.example.com/postings/99999")).to be_nil
  end

  it "keeps URLs with different queries apart" do
    create(:opportunity, url: "https://jobs.example.com/view?id=1")

    expect(described_class.find_duplicate(url: "https://jobs.example.com/view?id=2")).to be_nil
  end

  it "rejects a new record whose URL is already tracked, naming the existing one" do
    create(:opportunity, company: "Huntress", role: "Rails Engineer", url: "https://example.com/jobs/1")
    twin = build(:opportunity, url: "https://example.com/jobs/1/")

    expect(twin).not_to be_valid
    expect(twin.errors[:url].first).to include("Huntress")
  end

  it "does not flag a record against itself or when the URL is unchanged" do
    first = create(:opportunity, url: "https://example.com/jobs/1")

    expect(first.update(notes: "edited")).to be(true)
  end

  it "ignores a blank or missing URL" do
    expect(described_class.find_duplicate(url: nil)).to be_nil
    expect(described_class.find_duplicate(url: "")).to be_nil
  end

  it "finds records by external id in the text search" do
    match = create(:opportunity, external_id: "42472")
    create(:opportunity)

    expect(described_class.search("4247")).to contain_exactly(match)
  end
end

RSpec.describe Opportunity, ".stale_postings", type: :model do
  let(:cutoff) { Date.current - 14 }

  it "lists unverified and old-verified postings, never-checked first" do
    never = create(:opportunity, status: "recommended", last_verified_on: nil)
    old = create(:opportunity, status: "applied", last_verified_on: cutoff - 1)
    create(:opportunity, status: "applied", last_verified_on: cutoff)

    expect(described_class.stale_postings(cutoff)).to eq([ never, old ])
  end

  it "leaves out archived and late-stage records" do
    create(:opportunity, status: "talking", last_verified_on: nil)
    create(:opportunity, status: "closed", last_verified_on: nil)
    create(:opportunity, status: "recommended", last_verified_on: nil).archive!

    expect(described_class.stale_postings(cutoff)).to be_empty
  end
end
