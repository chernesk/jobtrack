import { Link } from "@inertiajs/react";
import { useDraggable, useDroppable } from "@dnd-kit/core";

import { formatDate } from "../lib/dates";
import type { Opportunity } from "../types";
import PayRange from "./PayRange";

interface CardBodyProps {
  opportunity: Opportunity;
}

function CardBody({ opportunity }: CardBodyProps) {
  return (
    <>
      <Link
        href={`/opportunities/${opportunity.id}`}
        className="font-medium text-slate-900 hover:underline dark:text-slate-100"
      >
        {opportunity.company}
      </Link>
      <p className="text-sm text-slate-600 dark:text-slate-400">{opportunity.role}</p>
      <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
        <PayRange min={opportunity.pay_min} max={opportunity.pay_max} unit={opportunity.pay_unit} />
      </p>
      {opportunity.follow_up_on && (
        <p className="text-xs text-slate-500 dark:text-slate-400">
          Follow up {formatDate(opportunity.follow_up_on)}
        </p>
      )}
    </>
  );
}

const CARD =
  "flex gap-2 rounded-lg border border-slate-200 bg-white p-3 shadow-sm dark:border-slate-700 dark:bg-slate-900";

interface BoardCardProps {
  opportunity: Opportunity;
  disabled: boolean;
}

// A card is both draggable and droppable: dropping on a card tells us which slot
// in the column the user wants. Only the grip is the drag handle, so the company
// link and the keyboard keep working normally.
export default function BoardCard({ opportunity, disabled }: BoardCardProps) {
  const { attributes, listeners, setNodeRef, setActivatorNodeRef, isDragging } = useDraggable({
    id: opportunity.id,
    disabled,
  });
  const { setNodeRef: setDropRef } = useDroppable({ id: opportunity.id });

  return (
    <li
      ref={(node) => {
        setNodeRef(node);
        setDropRef(node);
      }}
      className={`${CARD} ${isDragging ? "opacity-40" : ""}`}
    >
      <button
        type="button"
        ref={setActivatorNodeRef}
        aria-label={`Move ${opportunity.company}`}
        disabled={disabled}
        className="cursor-grab touch-none self-start rounded px-1 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 disabled:cursor-not-allowed"
        {...attributes}
        {...listeners}
      >
        ⠿
      </button>
      <div className="min-w-0 flex-1">
        <CardBody opportunity={opportunity} />
      </div>
    </li>
  );
}

// What follows the pointer while dragging.
export function BoardCardPreview({ opportunity }: CardBodyProps) {
  return (
    <div className={`${CARD} shadow-lg`}>
      <span aria-hidden="true" className="self-start px-1 text-slate-400">
        ⠿
      </span>
      <div className="min-w-0 flex-1">
        <CardBody opportunity={opportunity} />
      </div>
    </div>
  );
}
