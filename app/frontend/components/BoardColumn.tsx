import { useDroppable } from "@dnd-kit/core";
import { useId } from "react";

import { STATUS_LABELS } from "../lib/labels";
import type { Opportunity, Status } from "../types";
import BoardCard from "./BoardCard";

interface BoardColumnProps {
  status: Status;
  cards: Opportunity[];
  disabled: boolean;
}

export function columnId(status: Status): string {
  return `column:${status}`;
}

export default function BoardColumn({ status, cards, disabled }: BoardColumnProps) {
  const headingId = useId();
  const { setNodeRef, isOver } = useDroppable({ id: columnId(status) });

  return (
    <section
      aria-labelledby={headingId}
      className={`flex w-72 shrink-0 flex-col rounded-lg bg-slate-100 p-3 ${isOver ? "ring-2 ring-indigo-400" : ""}`}
    >
      <h2 id={headingId} className="mb-3 flex items-center justify-between text-sm font-semibold">
        {STATUS_LABELS[status]}
        <span className="rounded-full bg-white px-2 text-xs font-medium text-slate-600">
          {cards.length}
        </span>
      </h2>
      <ul ref={setNodeRef} className="min-h-16 flex-1 space-y-3">
        {cards.map((card) => (
          <BoardCard key={card.id} opportunity={card} disabled={disabled} />
        ))}
      </ul>
    </section>
  );
}
