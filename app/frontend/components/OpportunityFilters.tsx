import { useEffect, useState } from "react";

import { hasActiveFilters } from "../lib/opportunityQuery";
import { KIND_LABELS, STATUS_LABELS } from "../lib/labels";
import { KINDS, STATUSES, type Kind, type OpportunityQuery, type Status } from "../types";
import Button from "./Button";
import Field from "./Field";

const SEARCH_DELAY_MS = 300;

interface OpportunityFiltersProps {
  query: OpportunityQuery;
  onChange: (next: OpportunityQuery) => void;
  onClear: () => void;
}

export default function OpportunityFilters({ query, onChange, onClear }: OpportunityFiltersProps) {
  // The search box keeps its own copy of the text so typing feels instant; the
  // server only hears about it once the user pauses (see the effect below).
  const [search, setSearch] = useState(query.q);
  // The last search text we sent to the server, and the last `query.q` we saw.
  const [sentSearch, setSentSearch] = useState(query.q);
  const [seenQuery, setSeenQuery] = useState(query.q);

  // The server's filters changed. If that's the answer to our own request, do
  // nothing (the user may already be typing more). Otherwise it came from somewhere
  // else, such as the back button or "Clear filters", so reset the box to match.
  // This is React's "adjust state while rendering" pattern, used instead of an
  // effect that copies a prop into state (which causes an extra render and can
  // overwrite text the user is still typing).
  if (query.q !== seenQuery) {
    setSeenQuery(query.q);
    if (query.q !== sentSearch) {
      setSentSearch(query.q);
      setSearch(query.q);
    }
  }

  // Debounce: wait for a pause in typing before asking the server. The cleanup
  // function cancels the previous timer on every keystroke.
  useEffect(() => {
    if (search === sentSearch) return;
    const timer = setTimeout(() => {
      setSentSearch(search);
      onChange({ ...query, q: search });
    }, SEARCH_DELAY_MS);
    return () => clearTimeout(timer);
  }, [search, sentSearch, query, onChange]);

  return (
    <div className="flex flex-wrap items-end gap-4">
      <div className="min-w-56 flex-1">
        <Field label="Search">
          {(control) => (
            <input
              {...control}
              type="search"
              placeholder="Company or role"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
          )}
        </Field>
      </div>
      <Field label="Status">
        {(control) => (
          <select
            {...control}
            value={query.status}
            onChange={(event) => onChange({ ...query, status: event.target.value as Status | "" })}
          >
            <option value="">All statuses</option>
            {STATUSES.map((status) => (
              <option key={status} value={status}>
                {STATUS_LABELS[status]}
              </option>
            ))}
          </select>
        )}
      </Field>
      <Field label="Type">
        {(control) => (
          <select
            {...control}
            value={query.kind}
            onChange={(event) => onChange({ ...query, kind: event.target.value as Kind | "" })}
          >
            <option value="">All types</option>
            {KINDS.map((kind) => (
              <option key={kind} value={kind}>
                {KIND_LABELS[kind]}
              </option>
            ))}
          </select>
        )}
      </Field>
      {hasActiveFilters(query) && (
        <Button variant="secondary" onClick={onClear}>
          Clear filters
        </Button>
      )}
    </div>
  );
}
