import { STATUS_LABELS } from "../lib/labels";
import type { Status } from "../types";

const STATUS_STYLES: Record<Status, string> = {
  recommended: "bg-violet-100 text-violet-800 dark:bg-violet-900 dark:text-violet-200",
  not_contacted: "bg-slate-100 text-slate-700 dark:bg-slate-700 dark:text-slate-200",
  contacted: "bg-sky-100 text-sky-800 dark:bg-sky-900 dark:text-sky-200",
  applied: "bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-200",
  talking: "bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200",
  interviewing: "bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200",
  offer: "bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200",
  closed: "bg-zinc-200 text-zinc-600 dark:bg-zinc-700 dark:text-zinc-300",
};

interface StatusBadgeProps {
  status: Status;
}

export default function StatusBadge({ status }: StatusBadgeProps) {
  return (
    <span
      className={`inline-block rounded-full px-2.5 py-0.5 text-xs font-medium ${STATUS_STYLES[status]}`}
    >
      {STATUS_LABELS[status]}
    </span>
  );
}
