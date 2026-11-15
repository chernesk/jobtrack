import { formatDate } from "../lib/dates";
import { ACTIVITY_KIND_LABELS } from "../lib/labels";
import type { Activity } from "../types";
import EmptyState from "./EmptyState";

interface ActivityTimelineProps {
  activities: Activity[];
}

export default function ActivityTimeline({ activities }: ActivityTimelineProps) {
  if (activities.length === 0) {
    return (
      <EmptyState
        title="No activity yet"
        description="Log emails, calls and interviews as they happen."
      />
    );
  }

  return (
    <ol className="space-y-4 border-l-2 border-slate-200 pl-5">
      {activities.map((activity) => (
        <li key={activity.id}>
          <div className="flex items-baseline gap-2 text-sm">
            <span className="font-medium text-slate-900">
              {ACTIVITY_KIND_LABELS[activity.kind]}
            </span>
            <time dateTime={activity.occurred_on} className="text-slate-500">
              {formatDate(activity.occurred_on)}
            </time>
          </div>
          <p className="mt-1 whitespace-pre-wrap text-sm text-slate-700">{activity.body}</p>
        </li>
      ))}
    </ol>
  );
}
