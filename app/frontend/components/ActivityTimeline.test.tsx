import { render, screen } from "@testing-library/react";

import type { Activity } from "../types";
import ActivityTimeline from "./ActivityTimeline";

const ACTIVITIES: Activity[] = [
  { id: 2, kind: "interview", occurred_on: "2026-11-10", body: "Technical round" },
  { id: 1, kind: "email", occurred_on: "2026-11-01", body: "Sent intro\nand resume" },
];

describe("ActivityTimeline", () => {
  it("lists activities in the order given, with label, date and body", () => {
    render(<ActivityTimeline activities={ACTIVITIES} />);

    const items = screen.getAllByRole("listitem");
    expect(items.map((item) => item.textContent)).toEqual([
      "InterviewNov 10, 2026Technical round",
      "EmailNov 1, 2026Sent intro\nand resume",
    ]);
    expect(screen.getByText("Nov 10, 2026")).toHaveAttribute("datetime", "2026-11-10");
  });

  it("shows an empty state when there are no activities", () => {
    render(<ActivityTimeline activities={[]} />);

    expect(screen.getByText("No activity yet")).toBeInTheDocument();
    expect(screen.queryByRole("list")).not.toBeInTheDocument();
  });
});
