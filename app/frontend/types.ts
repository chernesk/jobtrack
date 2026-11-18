// Types for Inertia page props. Each type must match what the Rails controller
// passes to `render inertia:`. The enum unions below mirror the Rails enums in
// app/models/opportunity.rb and app/models/activity.rb.

// `as const` arrays give us both a runtime list (for board columns, <select>
// options) and a union type derived from it, so the two can never drift apart.
export const STATUSES = [
  "recommended",
  "not_contacted",
  "contacted",
  "applied",
  "talking",
  "interviewing",
  "offer",
  "closed",
] as const;
export type Status = (typeof STATUSES)[number];

export const CLOSED_REASONS = [
  "rejected",
  "withdrew",
  "posting_closed",
  "mistake",
  "other",
] as const;
export type ClosedReason = (typeof CLOSED_REASONS)[number];

export const APPLICATION_CHANNELS = ["email", "form", "ats", "referral", "other"] as const;
export type ApplicationChannel = (typeof APPLICATION_CHANNELS)[number];

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
  closed_reason: ClosedReason | null;
  pay_min: number | null;
  pay_max: number | null;
  pay_unit: PayUnit | null;
  url: string | null;
  contacted_on: string | null;
  follow_up_on: string | null;
  notes: string | null;
  position: number;
  // Set when the opportunity is archived (hidden, not deleted).
  archived_at: string | null;
  // The job board's own id for the posting; unique when present.
  external_id: string | null;
  // The date the posting was last confirmed still live.
  last_verified_on: string | null;
  // Which resume was sent, who to contact, and where the application went.
  resume_version: string | null;
  contact_name: string | null;
  application_channel: ApplicationChannel | null;
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
  // From the Settings page; `useAutoRefresh` reads it.
  auto_refresh: { enabled: boolean; seconds: number };
};

// Mirrors Setting#as_props. The ntfy token never reaches the browser; only whether one is saved.
export interface Settings {
  auto_refresh_enabled: boolean;
  auto_refresh_seconds: number;
  notifications_enabled: boolean;
  notify_when_nothing_due: boolean;
  hide_names: boolean;
  ntfy_url: string | null;
  ntfy_topic: string | null;
  app_url: string | null;
  ntfy_token_saved: boolean;
  // Which values the server environment supplies when the field is left blank.
  from_environment: {
    ntfy_url: boolean;
    ntfy_topic: boolean;
    ntfy_token: boolean;
    app_url: boolean;
    hide_names: boolean;
  };
}

export interface SettingsEditProps {
  settings: Settings;
}

// What the form sends. A blank `ntfy_token` means "keep the saved one".
export interface SettingsFormData {
  auto_refresh_enabled: boolean;
  auto_refresh_seconds: number;
  notifications_enabled: boolean;
  notify_when_nothing_due: boolean;
  hide_names: boolean;
  ntfy_url: string;
  ntfy_topic: string;
  ntfy_token: string;
  clear_ntfy_token: boolean;
  app_url: string;
}

export const REFRESH_CHOICES = [10, 15, 30, 60, 120] as const;

export type SortDirection = "asc" | "desc";

// The filters Rails applied, echoed back so the controls match the results.
// "" means "no filter" for the string fields (it's what a blank <select> sends).
export interface OpportunityQuery {
  q: string;
  status: Status | "";
  kind: Kind | "";
  dir: SortDirection;
  // true = show only archived opportunities.
  archived: boolean;
}

export interface OpportunitiesIndexProps {
  opportunities: Opportunity[];
  filters: OpportunityQuery;
}

// An activity in the dashboard feed, with the opportunity it belongs to.
export interface FeedActivity extends Activity {
  opportunity: { id: number; company: string };
}

export interface HomeIndexProps {
  // The server's "today" ("2026-11-15"), so overdue never depends on the browser.
  today: string;
  counts: Record<Status, number>;
  follow_ups_due: Opportunity[];
  recent_activity: FeedActivity[];
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
  closed_reason: ClosedReason | "";
  pay_min: string;
  pay_max: string;
  pay_unit: PayUnit | "";
  url: string;
  contacted_on: string;
  follow_up_on: string;
  notes: string;
  external_id: string;
  last_verified_on: string;
  resume_version: string;
  contact_name: string;
  application_channel: ApplicationChannel | "";
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
