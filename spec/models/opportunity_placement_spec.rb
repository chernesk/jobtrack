require "rails_helper"

RSpec.describe Opportunity, "column order and near-duplicate lookups" do
  describe "column position when the status changes by a plain update" do
    def positions(status)
      described_class.active.where(status: status).order(:position, :id).pluck(:company, :position)
    end

    it "joins the bottom of the new column instead of keeping its old number" do
      first = create(:opportunity, company: "First", status: "contacted")
      create(:opportunity, company: "Second", status: "contacted")
      create(:opportunity, company: "Applied A", status: "applied")
      create(:opportunity, company: "Applied B", status: "applied")

      first.update!(status: "applied")

      expect(positions("applied")).to eq([ [ "Applied A", 1 ], [ "Applied B", 2 ], [ "First", 3 ] ])
    end

    it "closes the gap it left in the old column" do
      create(:opportunity, company: "First", status: "contacted")
      middle = create(:opportunity, company: "Middle", status: "contacted")
      create(:opportunity, company: "Last", status: "contacted")

      middle.update!(status: "applied")

      expect(positions("contacted")).to eq([ [ "First", 1 ], [ "Last", 2 ] ])
    end

    it "does not touch the position when something other than the status changes" do
      create(:opportunity, status: "contacted")
      second = create(:opportunity, status: "contacted")

      second.update!(notes: "hello")

      expect(second.reload.position).to eq(2)
    end

    it "leaves move_to in charge of where a dragged card lands" do
      create(:opportunity, company: "A1", status: "applied")
      create(:opportunity, company: "A2", status: "applied")
      card = create(:opportunity, company: "Card", status: "contacted")

      card.move_to("applied", 0)

      expect(positions("applied")).to eq([ [ "Card", 1 ], [ "A1", 2 ], [ "A2", 3 ] ])
      expect(positions("contacted")).to be_empty
    end

    it "keeps working for later plain updates after a move" do
      card = create(:opportunity, company: "Card", status: "contacted")
      card.move_to("applied", 0)
      create(:opportunity, company: "Other", status: "talking")

      card.update!(status: "talking")

      expect(positions("talking")).to eq([ [ "Other", 1 ], [ "Card", 2 ] ])
    end
  end

  describe ".find_same_role" do
    it "matches ignoring case, punctuation and a legal suffix on the company" do
      existing = create(:opportunity, company: "Acme, Inc.", role: "Sr. Rails Engineer")

      expect(described_class.find_same_role(company: "ACME", role: "senior rails engineer")).to eq(existing)
    end

    it "does not match a different role or a different company" do
      create(:opportunity, company: "Acme", role: "Rails Engineer")

      expect(described_class.find_same_role(company: "Acme", role: "Staff Engineer")).to be_nil
      expect(described_class.find_same_role(company: "Acme Labs", role: "Rails Engineer")).to be_nil
    end

    it "includes archived records, and ignores blanks" do
      archived = create(:opportunity, company: "Acme", role: "Engineer").tap(&:archive!)

      expect(described_class.find_same_role(company: "Acme", role: "Engineer")).to eq(archived)
      expect(described_class.find_same_role(company: "", role: "Engineer")).to be_nil
    end
  end

  describe ".at_company" do
    it "lists the other opportunities at the same company, excluding the given one" do
      first = create(:opportunity, company: "Acme", role: "A")
      second = create(:opportunity, company: "ACME Inc", role: "B")
      create(:opportunity, company: "Other", role: "C")

      expect(described_class.at_company("Acme", excluding: first.id)).to eq([ second ])
    end
  end
end
