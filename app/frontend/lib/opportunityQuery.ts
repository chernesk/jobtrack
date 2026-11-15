import type { OpportunityQuery } from "../types";

export const DEFAULT_QUERY: OpportunityQuery = { q: "", status: "", kind: "", dir: "asc" };

export function hasActiveFilters(query: OpportunityQuery): boolean {
  return query.q !== "" || query.status !== "" || query.kind !== "";
}

// Builds the query string params for a visit. Blank filters and the default sort
// are left out so URLs stay short and shareable (`/opportunities?status=talking`).
export function toParams(query: OpportunityQuery): Record<string, string> {
  const params: Record<string, string> = {};
  if (query.q !== "") params["q"] = query.q;
  if (query.status !== "") params["status"] = query.status;
  if (query.kind !== "") params["kind"] = query.kind;
  if (query.dir !== DEFAULT_QUERY.dir) params["dir"] = query.dir;
  return params;
}
