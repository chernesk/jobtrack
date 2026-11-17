import { router } from "@inertiajs/react";
import { act, render, screen, within } from "@testing-library/react";
import type { AnchorHTMLAttributes, ReactNode } from "react";
import { beforeEach, vi } from "vitest";

import type { Opportunity, Status } from "../../types";
import Show from "./Show";

// Real drag and drop needs a browser (pointer events and layout), so these tests
// stand in for dnd-kit: the page's own `onDragEnd` handler is captured and called
// with the event dnd-kit would produce. What is tested is our logic: the optimistic
// update, the request, and the rollback. Dragging itself was checked in a browser.
let dragEnd: (event: { active: { id: number }; over: { id: string | number } | null }) => void;

vi.mock("@dnd-kit/core", () => ({
  DndContext: (props: { children: ReactNode; onDragEnd: typeof dragEnd }) => {
    dragEnd = props.onDragEnd;
    return <div>{props.children}</div>;
  },
  DragOverlay: () => null,
  KeyboardSensor: class {},
  PointerSensor: class {},
  useSensor: () => ({}),
  useSensors: () => [],
  useDraggable: () => ({
    attributes: {},
    listeners: {},
    setNodeRef: () => undefined,
    setActivatorNodeRef: () => undefined,
    isDragging: false,
  }),
  useDroppable: () => ({ setNodeRef: () => undefined, isOver: false }),
}));

vi.mock("@inertiajs/react", () => ({
  Link: (props: AnchorHTMLAttributes<HTMLAnchorElement>) => <a {...props} />,
  router: { patch: vi.fn(), delete: vi.fn() },
  usePage: () => ({
    url: "/board",
    props: { auth: { user: { email_address: "demo@example.com" } }, flash: {} },
  }),
}));

function card(id: number, company: string, status: Status): Opportunity {
  return {
    id,
    company,
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
    closed_reason: null,
    archived_at: null,
    external_id: null,
    last_verified_on: null,
  };
}

const OPPORTUNITIES = [
  card(1, "Acme Logistics", "contacted"),
  card(2, "Globex Payments", "contacted"),
  card(3, "Northwind Health", "talking"),
];

function companiesIn(column: string): string[] {
  const section = screen.getByRole("region", { name: new RegExp(`^${column}`) });
  return within(section)
    .queryAllByRole("listitem")
    .map((item) => within(item).getByRole("link").textContent ?? "");
}

type PatchOptions = {
  onSuccess?: () => void;
  onFinish?: () => void;
  onNetworkError?: () => boolean | void;
  onHttpException?: () => boolean | void;
};
const lastPatch = () => {
  const call = vi.mocked(router.patch).mock.calls.at(-1);
  return { url: call?.[0], data: call?.[1], options: (call?.[2] ?? {}) as PatchOptions };
};

describe("Board/Show", () => {
  beforeEach(() => {
    vi.mocked(router.patch).mockReset();
  });

  it("shows a column per status with counts, and each card in its column", () => {
    render(<Show opportunities={OPPORTUNITIES} />);

    expect(screen.getAllByRole("region")).toHaveLength(8);
    expect(companiesIn("Contacted")).toEqual(["Acme Logistics", "Globex Payments"]);
    expect(companiesIn("Talking")).toEqual(["Northwind Health"]);
    expect(companiesIn("Offer")).toEqual([]);
    expect(screen.getByRole("region", { name: /^Contacted/ })).toHaveTextContent("2");
  });

  it("moves a card at once and asks Rails to save the new status and position", () => {
    render(<Show opportunities={OPPORTUNITIES} />);

    act(() => dragEnd({ active: { id: 1 }, over: { id: 3 } }));

    expect(companiesIn("Contacted")).toEqual(["Globex Payments"]);
    expect(companiesIn("Talking")).toEqual(["Acme Logistics", "Northwind Health"]);
    expect(lastPatch()).toMatchObject({
      url: "/opportunities/1/move",
      data: { status: "talking", index: 0 },
    });
  });

  it("drops onto an empty column", () => {
    render(<Show opportunities={OPPORTUNITIES} />);

    act(() => dragEnd({ active: { id: 2 }, over: { id: "column:offer" } }));

    expect(companiesIn("Offer")).toEqual(["Globex Payments"]);
    expect(lastPatch().data).toEqual({ status: "offer", index: 0 });
  });

  it("keeps the move and shows no error when the server accepts it", () => {
    render(<Show opportunities={OPPORTUNITIES} />);
    act(() => dragEnd({ active: { id: 1 }, over: { id: "column:offer" } }));

    act(() => {
      lastPatch().options.onSuccess?.();
      lastPatch().options.onFinish?.();
    });

    expect(companiesIn("Offer")).toEqual(["Acme Logistics"]);
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();
  });

  it("puts the card back and explains when the server rejects the move", () => {
    render(<Show opportunities={OPPORTUNITIES} />);
    act(() => dragEnd({ active: { id: 1 }, over: { id: "column:offer" } }));
    expect(companiesIn("Offer")).toEqual(["Acme Logistics"]);

    // A rejected (or failed) request finishes without onSuccess.
    act(() => lastPatch().options.onFinish?.());

    expect(companiesIn("Offer")).toEqual([]);
    expect(companiesIn("Contacted")).toEqual(["Acme Logistics", "Globex Payments"]);
    expect(screen.getByRole("alert")).toHaveTextContent("Couldn't move Acme Logistics");
  });

  it("adopts fresh props from the server", () => {
    const { rerender } = render(<Show opportunities={OPPORTUNITIES} />);

    rerender(<Show opportunities={[card(1, "Acme Logistics", "closed")]} />);

    expect(companiesIn("Closed")).toEqual(["Acme Logistics"]);
    expect(companiesIn("Contacted")).toEqual([]);
  });

  it("ignores a drop that changes nothing, or lands outside every column", () => {
    render(<Show opportunities={OPPORTUNITIES} />);

    act(() => dragEnd({ active: { id: 1 }, over: { id: 1 } }));
    act(() => dragEnd({ active: { id: 1 }, over: null }));

    expect(router.patch).not.toHaveBeenCalled();
  });

  it("handles network and server errors itself rather than letting Inertia throw or show its modal", () => {
    render(<Show opportunities={OPPORTUNITIES} />);
    act(() => dragEnd({ active: { id: 1 }, over: { id: "column:offer" } }));

    expect(lastPatch().options.onNetworkError?.()).toBe(false);
    expect(lastPatch().options.onHttpException?.()).toBe(false);
  });
});
