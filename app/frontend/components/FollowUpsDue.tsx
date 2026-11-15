import { Link } from "@inertiajs/react";

import { dueLabel } from "../lib/dates";
import type { Opportunity } from "../types";
import EmptyState from "./EmptyState";
import StatusBadge from "./StatusBadge";

interface FollowUpsDueProps {
  opportunities: Opportunity[];
  today: string;
}

export default function FollowUpsDue({ opportunities, today }: FollowUpsDueProps) {
  if (opportunities.length === 0) {
    return <EmptyState title="Nothing to follow up on" description="You're all caught up." />;
  }

  return (
    <ul className="divide-y divide-slate-200 rounded-lg border border-slate-200 bg-white dark:divide-slate-700 dark:border-slate-700 dark:bg-slate-900">
      {opportunities.map((opportunity) => (
        <li key={opportunity.id} className="flex items-center justify-between gap-4 px-4 py-3">
          <div className="min-w-0">
            <Link href={`/opportunities/${opportunity.id}`} className="font-medium hover:underline">
              {opportunity.company}
            </Link>
            <p className="text-sm text-slate-600 dark:text-slate-400">{opportunity.role}</p>
          </div>
          <div className="flex shrink-0 items-center gap-3">
            <StatusBadge status={opportunity.status} />
            {/* follow_up_on is never null for a due item, but the type allows it. */}
            {opportunity.follow_up_on && (
              <span className="text-sm font-medium text-amber-700 dark:text-amber-300">
                {dueLabel(opportunity.follow_up_on, today)}
              </span>
            )}
          </div>
        </li>
      ))}
    </ul>
  );
}
