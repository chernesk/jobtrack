import type { ActivityKind, ClosedReason, Kind, PayUnit, Source, Status } from "../types";

// Human-readable labels. `Record<Status, string>` makes the compiler fail if a
// status is added to the union but forgotten here.
export const STATUS_LABELS: Record<Status, string> = {
  recommended: "Recommended",
  not_contacted: "Not contacted",
  contacted: "Contacted",
  applied: "Applied",
  talking: "Talking",
  interviewing: "Interviewing",
  offer: "Offer",
  closed: "Closed",
};

export const CLOSED_REASON_LABELS: Record<ClosedReason, string> = {
  rejected: "Rejected",
  withdrew: "I withdrew",
  posting_closed: "Posting closed",
  mistake: "Created by mistake",
  other: "Other",
};

export const KIND_LABELS: Record<Kind, string> = {
  full_time: "Full-time",
  contract_w2: "Contract (W2)",
  contract_c2c: "Contract (C2C)",
};

export const SOURCE_LABELS: Record<Source, string> = {
  network: "Network",
  recruiter: "Recruiter",
  agency: "Agency",
  job_board: "Job board",
  direct: "Direct",
};

export const PAY_UNIT_LABELS: Record<PayUnit, string> = {
  hourly: "hour",
  yearly: "year",
};

export const ACTIVITY_KIND_LABELS: Record<ActivityKind, string> = {
  email: "Email",
  call: "Call",
  interview: "Interview",
  note: "Note",
};
