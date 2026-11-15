import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { AnchorHTMLAttributes } from "react";
import { vi } from "vitest";

import type { Opportunity } from "../types";
import OpportunityTable from "./OpportunityTable";

vi.mock("@inertiajs/react", () => ({
  Link: (props: AnchorHTMLAttributes<HTMLAnchorElement>) => <a {...props} />,
}));

function build(overrides: Partial<Opportunity> = {}): Opportunity {
  return {
    id: 1,
    company: "Acme Logistics",
    role: "Senior Rails Engineer",
    kind: "full_time",
    source: "network",
    status: "talking",
    pay_min: 150000,
    pay_max: 180000,
    pay_unit: "yearly",
    url: null,
    contacted_on: null,
    follow_up_on: "2026-11-20",
    notes: null,
    position: 1,
    ...overrides,
  };
}

describe("OpportunityTable", () => {
  it("shows each opportunity's company, role, status, type, pay and follow-up date", () => {
    render(
      <OpportunityTable opportunities={[build()]} sortDirection="asc" onSortChange={vi.fn()} />,
    );

    const row = screen.getByRole("row", { name: /acme logistics/i });
    expect(within(row).getByText("Senior Rails Engineer")).toBeInTheDocument();
    expect(within(row).getByText("Talking")).toBeInTheDocument();
    expect(within(row).getByText("Full-time")).toBeInTheDocument();
    expect(within(row).getByText("$150,000 – $180,000 / year")).toBeInTheDocument();
    expect(within(row).getByText("Nov 20, 2026")).toBeInTheDocument();
  });

  it("shows placeholders for missing type and follow-up date", () => {
    render(
      <OpportunityTable
        opportunities={[build({ kind: null, follow_up_on: null, pay_min: null, pay_max: null })]}
        sortDirection="asc"
        onSortChange={vi.fn()}
      />,
    );

    const row = screen.getByRole("row", { name: /acme logistics/i });
    expect(within(row).getAllByText("—")).toHaveLength(2);
    expect(within(row).getByText("Pay not listed")).toBeInTheDocument();
  });

  it("renders one row per opportunity", () => {
    render(
      <OpportunityTable
        opportunities={[build({ id: 1 }), build({ id: 2, company: "Globex" })]}
        sortDirection="asc"
        onSortChange={vi.fn()}
      />,
    );

    // header row + 2 data rows
    expect(screen.getAllByRole("row")).toHaveLength(3);
  });

  it("reports the follow-up sort direction and toggles it on click", async () => {
    const onSortChange = vi.fn();
    const { rerender } = render(
      <OpportunityTable
        opportunities={[build()]}
        sortDirection="asc"
        onSortChange={onSortChange}
      />,
    );

    expect(screen.getByRole("columnheader", { name: /follow-up/i })).toHaveAttribute(
      "aria-sort",
      "ascending",
    );
    await userEvent.click(screen.getByRole("button", { name: /follow-up/i }));
    expect(onSortChange).toHaveBeenLastCalledWith("desc");

    rerender(
      <OpportunityTable
        opportunities={[build()]}
        sortDirection="desc"
        onSortChange={onSortChange}
      />,
    );
    expect(screen.getByRole("columnheader", { name: /follow-up/i })).toHaveAttribute(
      "aria-sort",
      "descending",
    );
    await userEvent.click(screen.getByRole("button", { name: /follow-up/i }));
    expect(onSortChange).toHaveBeenLastCalledWith("asc");
  });

  it("links each row to its edit form", () => {
    render(
      <OpportunityTable
        opportunities={[build({ id: 7, company: "Northwind Health" })]}
        sortDirection="asc"
        onSortChange={vi.fn()}
      />,
    );

    expect(screen.getByRole("link", { name: "Edit Northwind Health" })).toHaveAttribute(
      "href",
      "/opportunities/7/edit",
    );
  });

  it("links each company to its detail page", () => {
    render(
      <OpportunityTable
        opportunities={[build({ id: 7, company: "Northwind Health" })]}
        sortDirection="asc"
        onSortChange={vi.fn()}
      />,
    );

    expect(screen.getByRole("link", { name: "Northwind Health" })).toHaveAttribute(
      "href",
      "/opportunities/7",
    );
  });
});
