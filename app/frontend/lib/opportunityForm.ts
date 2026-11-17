import type { Opportunity, OpportunityFormData } from "../types";

export const EMPTY_FORM: OpportunityFormData = {
  company: "",
  role: "",
  kind: "",
  source: "",
  status: "not_contacted",
  closed_reason: "",
  pay_min: "",
  pay_max: "",
  pay_unit: "",
  url: "",
  contacted_on: "",
  follow_up_on: "",
  notes: "",
};

// Rails sends null for anything empty; inputs need "" to stay controlled.
export function toFormData(opportunity?: Opportunity): OpportunityFormData {
  if (!opportunity) return EMPTY_FORM;
  return {
    company: opportunity.company,
    role: opportunity.role,
    kind: opportunity.kind ?? "",
    source: opportunity.source ?? "",
    status: opportunity.status,
    closed_reason: opportunity.closed_reason ?? "",
    pay_min: opportunity.pay_min?.toString() ?? "",
    pay_max: opportunity.pay_max?.toString() ?? "",
    pay_unit: opportunity.pay_unit ?? "",
    url: opportunity.url ?? "",
    contacted_on: opportunity.contacted_on ?? "",
    follow_up_on: opportunity.follow_up_on ?? "",
    notes: opportunity.notes ?? "",
  };
}

export type RequiredErrors = Partial<Record<"company" | "role", string>>;

// A UX nicety so an empty form gets feedback without a round trip. Rails still
// validates everything and is the authority.
export function requiredErrors(data: OpportunityFormData): RequiredErrors {
  const errors: RequiredErrors = {};
  if (!data.company.trim()) errors.company = "Company is required";
  if (!data.role.trim()) errors.role = "Role is required";
  return errors;
}
