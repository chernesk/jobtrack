// Types for Inertia page props. Each type must match what the Rails controller
// passes to `render inertia:`. The enum unions below mirror the Rails enums in
// app/models/opportunity.rb and app/models/activity.rb.

// `as const` arrays give us both a runtime list (for board columns, <select>
// options) and a union type derived from it, so the two can never drift apart.
export const STATUSES = [
  "not_contacted",
  "contacted",
  "talking",
  "interviewing",
  "offer",
  "closed",
] as const;
export type Status = (typeof STATUSES)[number];

export const KINDS = ["full_time", "contract_w2", "contract_c2c"] as const;
export type Kind = (typeof KINDS)[number];

export const SOURCES = ["network", "recruiter", "agency", "job_board", "direct"] as const;
export type Source = (typeof SOURCES)[number];

export const PAY_UNITS = ["hourly", "yearly"] as const;
export type PayUnit = (typeof PAY_UNITS)[number];

export const ACTIVITY_KINDS = ["email", "call", "interview", "note"] as const;
export type ActivityKind = (typeof ACTIVITY_KINDS)[number];

// Dates arrive from Rails as ISO strings ("2026-11-14"), not Date objects.
export interface Opportunity {
  id: number;
  company: string;
  role: string;
  kind: Kind | null;
  source: Source | null;
  status: Status;
  pay_min: number | null;
  pay_max: number | null;
  pay_unit: PayUnit | null;
  url: string | null;
  contacted_on: string | null;
  follow_up_on: string | null;
  notes: string | null;
  position: number;
}

export interface Activity {
  id: number;
  kind: ActivityKind;
  occurred_on: string;
  body: string;
}

export interface CurrentUser {
  email_address: string;
}

// Shared by every page via `inertia_share` in ApplicationController.
// A `type` (not `interface`) so it is assignable to Inertia's PageProps.
export type SharedProps = {
  auth: { user: CurrentUser | null };
  flash: { notice?: string; alert?: string };
};

export type SortDirection = "asc" | "desc";

// The filters Rails applied, echoed back so the controls match the results.
// "" means "no filter" for the string fields (it's what a blank <select> sends).
export interface OpportunityQuery {
  q: string;
  status: Status | "";
  kind: Kind | "";
  dir: SortDirection;
}

export interface OpportunitiesIndexProps {
  opportunities: Opportunity[];
  filters: OpportunityQuery;
}

export interface HomeIndexProps {
  user: CurrentUser;
}

// What the new/edit form holds while the user types. Every field is a string
// because that is what inputs produce; "" means "not provided" and Rails turns it
// into nil (see OpportunitiesController#opportunity_params).
export interface OpportunityFormData {
  company: string;
  role: string;
  kind: Kind | "";
  source: Source | "";
  status: Status;
  pay_min: string;
  pay_max: string;
  pay_unit: PayUnit | "";
  url: string;
  contacted_on: string;
  follow_up_on: string;
  notes: string;
}

export interface OpportunityEditProps {
  opportunity: Opportunity;
}

export interface OpportunityShowProps {
  opportunity: Opportunity;
  activities: Activity[];
}

// The inline "add activity" form. `occurred_on` is an ISO date string.
export interface ActivityFormData {
  kind: ActivityKind;
  occurred_on: string;
  body: string;
}

export interface BoardShowProps {
  opportunities: Opportunity[];
}
