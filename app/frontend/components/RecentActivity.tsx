import { Link } from "@inertiajs/react";

import { formatDate } from "../lib/dates";
import { ACTIVITY_KIND_LABELS } from "../lib/labels";
import type { FeedActivity } from "../types";
import EmptyState from "./EmptyState";

interface RecentActivityProps {
  activities: FeedActivity[];
}

export default function RecentActivity({ activities }: RecentActivityProps) {
  if (activities.length === 0) {
    return (
      <EmptyState title="No activity yet" description="Log emails and calls from an opportunity." />
    );
  }

  return (
    <ul className="divide-y divide-slate-200 rounded-lg border border-slate-200 bg-white dark:divide-slate-700 dark:border-slate-700 dark:bg-slate-900">
      {activities.map((activity) => (
        <li key={activity.id} className="px-4 py-3">
          <div className="flex items-baseline gap-2 text-sm">
            <span className="font-medium">{ACTIVITY_KIND_LABELS[activity.kind]}</span>
            <Link href={`/opportunities/${activity.opportunity.id}`} className="hover:underline">
              {activity.opportunity.company}
            </Link>
            <time dateTime={activity.occurred_on} className="text-slate-500 dark:text-slate-400">
              {formatDate(activity.occurred_on)}
            </time>
          </div>
          <p className="mt-1 text-sm text-slate-700 dark:text-slate-300">{activity.body}</p>
        </li>
      ))}
    </ul>
  );
}
