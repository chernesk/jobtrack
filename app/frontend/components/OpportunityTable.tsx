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

const HEADER = "px-4 py-2 text-left text-xs font-semibold uppercase tracking-wide text-slate-500";

export default function OpportunityTable({
  opportunities,
  sortDirection,
  onSortChange,
}: OpportunityTableProps) {
  const nextDirection: SortDirection = sortDirection === "asc" ? "desc" : "asc";

  return (
    <div className="overflow-x-auto rounded-lg border border-slate-200 bg-white">
      <table className="min-w-full divide-y divide-slate-200 text-sm">
        <thead className="bg-slate-50">
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
                className="uppercase hover:text-slate-900"
              >
                Follow-up {sortDirection === "asc" ? "↑" : "↓"}
              </button>
            </th>
            <th scope="col" className={HEADER}>
              <span className="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {opportunities.map((opportunity) => (
            <tr key={opportunity.id}>
              <td className="px-4 py-3">
                <div className="font-medium text-slate-900">{opportunity.company}</div>
                <div className="text-slate-500">{opportunity.role}</div>
              </td>
              <td className="px-4 py-3">
                <StatusBadge status={opportunity.status} />
              </td>
              <td className="px-4 py-3 text-slate-700">
                {opportunity.kind ? KIND_LABELS[opportunity.kind] : "—"}
              </td>
              <td className="px-4 py-3 text-slate-700">
                <PayRange
                  min={opportunity.pay_min}
                  max={opportunity.pay_max}
                  unit={opportunity.pay_unit}
                />
              </td>
              <td className="px-4 py-3 text-slate-700">
                {opportunity.follow_up_on ? formatDate(opportunity.follow_up_on) : "—"}
              </td>
              <td className="px-4 py-3 text-right">
                <Link
                  href={`/opportunities/${opportunity.id}/edit`}
                  aria-label={`Edit ${opportunity.company}`}
                  className="text-slate-600 hover:text-slate-900"
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
