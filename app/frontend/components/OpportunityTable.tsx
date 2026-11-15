import { Link } from "@inertiajs/react";

import { formatDate } from "../lib/dates";
import { KIND_LABELS } from "../lib/labels";
import type { Opportunity, SortDirection } from "../types";
import PayRange from "./PayRange";
import StatusBadge from "./StatusBadge";

interface OpportunityTableProps {
  opportunities: Opportunity[];
  sortDirection: SortDirection;
  onSortChange: (direction: SortDirection) => void;
}

const HEADER =
  "px-4 py-2 text-left text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400";

export default function OpportunityTable({
  opportunities,
  sortDirection,
  onSortChange,
}: OpportunityTableProps) {
  const nextDirection: SortDirection = sortDirection === "asc" ? "desc" : "asc";

  return (
    <div className="overflow-x-auto rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900">
      <table className="min-w-full divide-y divide-slate-200 dark:divide-slate-700 text-sm">
        <thead className="bg-slate-50 dark:bg-slate-800/60">
          <tr>
            <th scope="col" className={HEADER}>
              Company
            </th>
            <th scope="col" className={HEADER}>
              Status
            </th>
            <th scope="col" className={HEADER}>
              Type
            </th>
            <th scope="col" className={HEADER}>
              Pay
            </th>
            <th
              scope="col"
              aria-sort={sortDirection === "asc" ? "ascending" : "descending"}
              className={HEADER}
            >
              <button
                type="button"
                onClick={() => onSortChange(nextDirection)}
                className="uppercase hover:text-slate-900 dark:hover:text-slate-100"
              >
                Follow-up {sortDirection === "asc" ? "↑" : "↓"}
              </button>
            </th>
            <th scope="col" className={HEADER}>
              <span className="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
          {opportunities.map((opportunity) => (
            <tr key={opportunity.id}>
              <td className="px-4 py-3">
                <Link
                  href={`/opportunities/${opportunity.id}`}
                  className="font-medium text-slate-900 dark:text-slate-100 hover:underline"
                >
                  {opportunity.company}
                </Link>
                <div className="text-slate-500 dark:text-slate-400">{opportunity.role}</div>
              </td>
              <td className="px-4 py-3">
                <StatusBadge status={opportunity.status} />
              </td>
              <td className="px-4 py-3 text-slate-700 dark:text-slate-300">
                {opportunity.kind ? KIND_LABELS[opportunity.kind] : "—"}
              </td>
              <td className="px-4 py-3 text-slate-700 dark:text-slate-300">
                <PayRange
                  min={opportunity.pay_min}
                  max={opportunity.pay_max}
                  unit={opportunity.pay_unit}
                />
              </td>
              <td className="px-4 py-3 text-slate-700 dark:text-slate-300">
                {opportunity.follow_up_on ? formatDate(opportunity.follow_up_on) : "—"}
              </td>
              <td className="px-4 py-3 text-right">
                <Link
                  href={`/opportunities/${opportunity.id}/edit`}
                  aria-label={`Edit ${opportunity.company}`}
                  className="text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100"
                >
                  Edit
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
