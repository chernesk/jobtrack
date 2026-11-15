import { render, screen, within } from "@testing-library/react";
import type { AnchorHTMLAttributes } from "react";
import { vi } from "vitest";

import { STATUSES, type HomeIndexProps, type Opportunity, type Status } from "../../types";
import Index from "./Index";

vi.mock("@inertiajs/react", () => ({
  Link: (props: AnchorHTMLAttributes<HTMLAnchorElement>) => <a {...props} />,
  router: { delete: vi.fn() },
  usePage: () => ({
    url: "/",
    props: { auth: { user: { email_address: "demo@example.com" } }, flash: {} },
  }),
}));

function due(id: number, company: string, follow_up_on: string, status: Status): Opportunity {
  return {
    id,
    company,
    role: "Rails Engineer",
    kind: null,
    source: null,
    status,
    pay_min: null,
    pay_max: null,
    pay_unit: null,
    url: null,
    contacted_on: null,
    follow_up_on,
    notes: null,
    position: id,
  };
}

const EMPTY_COUNTS = Object.fromEntries(STATUSES.map((s) => [s, 0])) as Record<Status, number>;

function props(overrides: Partial<HomeIndexProps> = {}): HomeIndexProps {
  return {
    today: "2026-11-15",
    counts: EMPTY_COUNTS,
    follow_ups_due: [],
    recent_activity: [],
    ...overrides,
  };
}

describe("Home/Index (dashboard)", () => {
  it("shows a count tile per status that links to the filtered list", () => {
    render(<Index {...props({ counts: { ...EMPTY_COUNTS, talking: 4, offer: 1 } })} />);

    const talking = screen.getByRole("link", { name: /Talking/ });
    expect(talking).toHaveTextContent("4");
    expect(talking).toHaveAttribute("href", "/opportunities?status=talking");
    expect(screen.getByRole("link", { name: /Offer/ })).toHaveTextContent("1");
    expect(screen.getByRole("link", { name: /Not contacted/ })).toHaveTextContent("0");
  });

  it("lists follow-ups due, saying how overdue each is", () => {
    render(
      <Index
        {...props({
          follow_ups_due: [
            due(1, "Wayne Textiles", "2026-11-13", "talking"),
            due(2, "Hooli Maps", "2026-11-15", "contacted"),
          ],
        })}
      />,
    );

    const section = screen.getByRole("region", { name: "Follow-ups due" });
    const items = within(section).getAllByRole("listitem");
    expect(items.map((item) => item.textContent)).toEqual([
      expect.stringContaining("2 days overdue"),
      expect.stringContaining("Due today"),
    ]);
    expect(within(section).getByRole("link", { name: "Wayne Textiles" })).toHaveAttribute(
      "href",
      "/opportunities/1",
    );
  });

  it("says so when there is nothing to follow up on", () => {
    render(<Index {...props()} />);

    expect(screen.getByText("Nothing to follow up on")).toBeInTheDocument();
  });

  it("shows recent activity with the company it belongs to", () => {
    render(
      <Index
        {...props({
          recent_activity: [
            {
              id: 9,
              kind: "call",
              occurred_on: "2026-11-12",
              body: "Phone screen went well",
              opportunity: { id: 3, company: "Stark Robotics" },
            },
          ],
        })}
      />,
    );

    const section = screen.getByRole("region", { name: "Recent activity" });
    expect(within(section).getByText("Phone screen went well")).toBeInTheDocument();
    expect(within(section).getByText("Nov 12, 2026")).toBeInTheDocument();
    expect(within(section).getByRole("link", { name: "Stark Robotics" })).toHaveAttribute(
      "href",
      "/opportunities/3",
    );
  });

  it("shows an empty state when there is no activity", () => {
    render(<Index {...props()} />);

    expect(screen.getByText("No activity yet")).toBeInTheDocument();
  });
});
