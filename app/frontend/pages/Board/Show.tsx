import {
  DndContext,
  DragOverlay,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type Announcements,
  type DragEndEvent,
  type DragStartEvent,
} from "@dnd-kit/core";
import { router } from "@inertiajs/react";
import { useState } from "react";

import { BoardCardPreview } from "../../components/BoardCard";
import BoardColumn from "../../components/BoardColumn";
import Layout from "../../components/Layout";
import { boardCoordinates } from "../../lib/boardKeyboard";
import { findStatus, groupByStatus, moveCard, type BoardColumns } from "../../lib/board";
import { STATUS_LABELS } from "../../lib/labels";
import { STATUSES, type BoardShowProps, type Opportunity, type Status } from "../../types";

// Column drop targets use ids like "column:talking"; cards use their numeric id.
function parseColumn(id: string | number): Status | null {
  if (typeof id !== "string" || !id.startsWith("column:")) return null;
  return STATUSES.find((status) => status === id.slice("column:".length)) ?? null;
}

export default function Show({ opportunities }: BoardShowProps) {
  // The board is the one place that holds UI state of its own: the columns as the
  // user has arranged them, which can briefly run ahead of the server (optimistic).
  const [columns, setColumns] = useState(() => groupByStatus(opportunities));
  const [seenProps, setSeenProps] = useState(opportunities);
  const [activeCard, setActiveCard] = useState<Opportunity | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Rails sent fresh props (after a move succeeds or fails, or on any visit): they
  // are the truth, so adopt them. "Adjust state while rendering", not an effect.
  if (opportunities !== seenProps) {
    setSeenProps(opportunities);
    setColumns(groupByStatus(opportunities));
  }

  // A small distance before a drag starts, so a click on the grip isn't a drag.
  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 5 } }),
    useSensor(KeyboardSensor, { coordinateGetter: boardCoordinates }),
  );

  const cardById = (id: string | number): Opportunity | undefined =>
    STATUSES.flatMap((status) => columns[status]).find((card) => card.id === id);

  // Spoken by screen readers during keyboard drags; default text would say "item 7".
  const announcements: Announcements = {
    onDragStart: ({ active }) => `Picked up ${cardById(active.id)?.company ?? "card"}.`,
    onDragOver: ({ active, over }) => {
      const status = over && (parseColumn(over.id) ?? findStatus(columns, Number(over.id)));
      return status
        ? `${cardById(active.id)?.company} is over ${STATUS_LABELS[status]}.`
        : undefined;
    },
    onDragEnd: ({ active }) => `Dropped ${cardById(active.id)?.company ?? "card"}.`,
    onDragCancel: ({ active }) => `Cancelled moving ${cardById(active.id)?.company ?? "card"}.`,
  };

  function handleDragStart({ active }: DragStartEvent) {
    setError(null);
    setActiveCard(cardById(active.id) ?? null);
  }

  function handleDragEnd({ active, over }: DragEndEvent) {
    setActiveCard(null);
    if (!over) return;

    const overColumn = parseColumn(over.id);
    const overCardId = overColumn ? null : Number(over.id);
    const toStatus = overColumn ?? findStatus(columns, Number(over.id));
    if (!toStatus) return;

    const move = moveCard(columns, Number(active.id), toStatus, overCardId);
    if (!move) return;

    sendMove(move.card, move.status, move.index, move.columns);
  }

  function sendMove(card: Opportunity, status: Status, index: number, next: BoardColumns) {
    const before: BoardColumns = columns;

    // Optimistic: show the result now, then ask the server.
    setColumns(next);
    setSaving(true);

    let saved = false;
    router.patch(
      `/opportunities/${card.id}/move`,
      { status, index },
      {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
          saved = true;
        },
        // We explain failures ourselves (below), so tell Inertia not to also throw
        // on a network error or open its error modal for a 4xx/5xx response.
        onNetworkError: () => false,
        onHttpException: () => false,
        // `onFinish` runs for every outcome (validation error, 500, network
        // failure), so one check here covers all the ways a move can fail.
        onFinish: () => {
          setSaving(false);
          if (!saved) {
            setColumns(before);
            setError(`Couldn't move ${card.company}. It has been put back.`);
          }
        },
      },
    );
  }

  return (
    <Layout>
      <h1 className="text-2xl font-semibold">Board</h1>

      {error && (
        <p
          role="alert"
          className="mt-4 rounded bg-red-50 px-4 py-2 text-sm text-red-800 dark:bg-red-950 dark:text-red-200"
        >
          {error}
        </p>
      )}

      <DndContext
        sensors={sensors}
        accessibility={{ announcements }}
        onDragStart={handleDragStart}
        onDragEnd={handleDragEnd}
        onDragCancel={() => setActiveCard(null)}
      >
        <div className="mt-6 flex items-start gap-4 overflow-x-auto pb-4">
          {STATUSES.map((status) => (
            <BoardColumn key={status} status={status} cards={columns[status]} disabled={saving} />
          ))}
        </div>
        <DragOverlay>{activeCard && <BoardCardPreview opportunity={activeCard} />}</DragOverlay>
      </DndContext>
    </Layout>
  );
}
