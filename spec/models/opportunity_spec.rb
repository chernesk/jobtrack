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
      expect(described_class.statuses.keys).to eq(%w[not_contacted contacted talking interviewing offer closed])
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
