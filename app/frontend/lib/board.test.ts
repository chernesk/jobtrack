import type { Opportunity, Status } from "../types";
import { findStatus, groupByStatus, moveCard, type Move } from "./board";

function card(id: number, status: Status): Opportunity {
  return {
    id,
    company: `Company ${id}`,
    role: "Engineer",
    kind: null,
    source: null,
    status,
    pay_min: null,
    pay_max: null,
    pay_unit: null,
    url: null,
    contacted_on: null,
    follow_up_on: null,
    notes: null,
    position: id,
  };
}

const board = () =>
  groupByStatus([
    card(1, "contacted"),
    card(2, "contacted"),
    card(3, "contacted"),
    card(4, "talking"),
  ]);
// Fails the test with a clear message instead of using a non-null assertion.
function moved(move: Move | null): Move {
  if (!move) throw new Error("expected the card to move");
  return move;
}
const ids = (cards: Opportunity[]) => cards.map((c) => c.id);

describe("groupByStatus", () => {
  it("has a column for every status, keeping each column's order", () => {
    const columns = board();

    expect(Object.keys(columns)).toHaveLength(6);
    expect(ids(columns.contacted)).toEqual([1, 2, 3]);
    expect(ids(columns.offer)).toEqual([]);
  });
});

describe("moveCard", () => {
  it("takes the slot of the card it is dropped on, moving down", () => {
    const move = moved(moveCard(board(), 1, "contacted", 3));

    expect(ids(move.columns.contacted)).toEqual([2, 3, 1]);
    expect(move).toMatchObject({ status: "contacted", index: 2 });
  });

  it("takes the slot of the card it is dropped on, moving up", () => {
    const move = moved(moveCard(board(), 3, "contacted", 1));

    expect(ids(move.columns.contacted)).toEqual([3, 1, 2]);
    expect(move.index).toBe(0);
  });

  it("moves to another column before the card it is dropped on, and updates its status", () => {
    const move = moved(moveCard(board(), 2, "talking", 4));

    expect(ids(move.columns.talking)).toEqual([2, 4]);
    expect(ids(move.columns.contacted)).toEqual([1, 3]);
    expect(move.card.status).toBe("talking");
    expect(move.index).toBe(0);
  });

  it("goes to the end when dropped on the column itself", () => {
    const move = moved(moveCard(board(), 1, "talking", null));

    expect(ids(move.columns.talking)).toEqual([4, 1]);
    expect(move.index).toBe(1);
  });

  it("does not mutate the original board", () => {
    const original = board();
    moveCard(original, 1, "talking", null);

    expect(ids(original.contacted)).toEqual([1, 2, 3]);
  });

  it("returns null when nothing would change", () => {
    expect(moveCard(board(), 2, "contacted", 2)).toBeNull();
    expect(moveCard(board(), 3, "contacted", null)).toBeNull();
  });

  it("returns null for an unknown card", () => {
    expect(moveCard(board(), 99, "talking", null)).toBeNull();
  });
});

describe("findStatus", () => {
  it("finds the column a card is in", () => {
    expect(findStatus(board(), 4)).toBe("talking");
    expect(findStatus(board(), 99)).toBeNull();
  });
});
