import type { Opportunity } from "../types";
import { EMPTY_FORM, requiredErrors, toFormData } from "./opportunityForm";

const OPPORTUNITY: Opportunity = {
  id: 1,
  company: "Acme Logistics",
  role: "Rails Engineer",
  kind: null,
  source: "network",
  status: "talking",
  pay_min: 90,
  pay_max: null,
  pay_unit: "hourly",
  url: null,
  contacted_on: "2026-11-01",
  follow_up_on: null,
  notes: null,
  position: 1,
};

describe("toFormData", () => {
  it("starts a new record empty, in the first status", () => {
    expect(toFormData()).toEqual(EMPTY_FORM);
    expect(EMPTY_FORM.status).toBe("not_contacted");
  });

  it("turns nulls into empty strings and numbers into strings", () => {
    expect(toFormData(OPPORTUNITY)).toMatchObject({
      kind: "",
      source: "network",
      pay_min: "90",
      pay_max: "",
      url: "",
      contacted_on: "2026-11-01",
      notes: "",
    });
  });
});

describe("requiredErrors", () => {
  it("flags blank and whitespace-only company and role", () => {
    expect(requiredErrors({ ...EMPTY_FORM, company: "   " })).toEqual({
      company: "Company is required",
      role: "Role is required",
    });
  });

  it("returns nothing when both are present", () => {
    expect(requiredErrors({ ...EMPTY_FORM, company: "Acme", role: "Dev" })).toEqual({});
  });
});
