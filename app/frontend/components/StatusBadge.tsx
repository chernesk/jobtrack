import { STATUS_LABELS } from "../lib/labels";
import type { Status } from "../types";

const STATUS_STYLES: Record<Status, string> = {
  not_contacted: "bg-slate-100 text-slate-700",
  contacted: "bg-sky-100 text-sky-800",
  talking: "bg-indigo-100 text-indigo-800",
  interviewing: "bg-amber-100 text-amber-800",
  offer: "bg-emerald-100 text-emerald-800",
  closed: "bg-zinc-200 text-zinc-600",
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
