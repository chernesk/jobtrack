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
end
