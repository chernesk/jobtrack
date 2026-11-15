import { STATUSES, type Opportunity, type Status } from "../types";

export type BoardColumns = Record<Status, Opportunity[]>;

// Rails sends one flat list ordered by `position`; the board needs one list per
// status. Order within a status is preserved.
export function groupByStatus(opportunities: Opportunity[]): BoardColumns {
  const columns = Object.fromEntries(
    STATUSES.map((status) => [status, []]),
  ) as unknown as BoardColumns;
  for (const opportunity of opportunities) {
    columns[opportunity.status].push(opportunity);
  }
  return columns;
}

export function findStatus(columns: BoardColumns, cardId: number): Status | null {
  return STATUSES.find((status) => columns[status].some((card) => card.id === cardId)) ?? null;
}

export interface Move {
  columns: BoardColumns;
  card: Opportunity;
  status: Status;
  // Where the card now sits among the column's *other* cards (0-based). This is
  // exactly what the server's `move` action expects.
  index: number;
}

// Pure: returns the board as it should look after dropping `cardId` into
// `toStatus`, or null if nothing would change. Dropping on a card takes that
// card's slot (like `arrayMove`); dropping on the column itself goes to the end.
export function moveCard(
  columns: BoardColumns,
  cardId: number,
  toStatus: Status,
  overCardId: number | null,
): Move | null {
  const fromStatus = findStatus(columns, cardId);
  const card = fromStatus && columns[fromStatus].find((candidate) => candidate.id === cardId);
  if (!fromStatus || !card) return null;

  const destination = columns[toStatus];
  const overIndex =
    overCardId === null ? -1 : destination.findIndex((candidate) => candidate.id === overCardId);
  const others = destination.filter((candidate) => candidate.id !== cardId);
  const index = overIndex === -1 ? others.length : Math.min(overIndex, others.length);

  if (fromStatus === toStatus && destination.findIndex((c) => c.id === cardId) === index) {
    return null;
  }

  const moved = { ...card, status: toStatus };
  const next: BoardColumns = {
    ...columns,
    [fromStatus]: columns[fromStatus].filter((candidate) => candidate.id !== cardId),
    [toStatus]: [...others.slice(0, index), moved, ...others.slice(index)],
  };
  return { columns: next, card: moved, status: toStatus, index };
}
