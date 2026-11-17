import { Link } from "@inertiajs/react";

import { STATUS_LABELS } from "../lib/labels";
import { STATUSES, type Status } from "../types";

interface StatusCountsProps {
  counts: Record<Status, number>;
}

// One tile per status; each links to the list filtered to that status.
export default function StatusCounts({ counts }: StatusCountsProps) {
  return (
    <ul className="grid grid-cols-2 gap-3 sm:grid-cols-4">
      {STATUSES.map((status) => (
        <li key={status}>
          <Link
            href={`/opportunities?status=${status}`}
            className="block rounded-lg border border-slate-200 bg-white p-4 hover:border-slate-400 dark:border-slate-700 dark:bg-slate-900 dark:hover:border-slate-500"
          >
            <span className="block text-2xl font-semibold">{counts[status]}</span>
            <span className="text-sm text-slate-600 dark:text-slate-400">
              {STATUS_LABELS[status]}
            </span>
          </Link>
        </li>
      ))}
    </ul>
  );
}
