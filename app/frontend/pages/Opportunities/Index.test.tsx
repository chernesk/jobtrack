import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { AnchorHTMLAttributes } from "react";
import { beforeEach, vi } from "vitest";

import type { Opportunity, OpportunityQuery } from "../../types";
import Index from "./Index";

vi.mock("@inertiajs/react", () => ({
  Link: (props: AnchorHTMLAttributes<HTMLAnchorElement>) => <a {...props} />,
  router: { get: vi.fn(), delete: vi.fn() },
  usePage: () => ({
    url: "/opportunities",
    props: { auth: { user: { email_address: "demo@example.com" } }, flash: {} },
  }),
}));

const NO_FILTERS: OpportunityQuery = { q: "", status: "", kind: "", dir: "asc", archived: false };
const VISIT_OPTIONS = { preserveState: true, replace: true };

function build(id: number, company: string): Opportunity {
  return {
    id,
    company,
    role: "Rails Engineer",
    kind: "full_time",
    source: null,
    status: "contacted",
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
  };
}

describe("Opportunities/Index", () => {
  beforeEach(() => {
    vi.mocked(router.get).mockClear();
  });

  it("lists the opportunities", () => {
    render(
      <Index
        opportunities={[build(1, "Acme Logistics"), build(2, "Northwind Health")]}
        filters={NO_FILTERS}
      />,
    );

    expect(screen.getByRole("heading", { name: "Opportunities" })).toBeInTheDocument();
    expect(screen.getByText("Acme Logistics")).toBeInTheDocument();
    expect(screen.getByText("Northwind Health")).toBeInTheDocument();
  });

  it("asks Rails for filtered results when a filter changes, keeping the URL clean", async () => {
    render(<Index opportunities={[build(1, "Acme Logistics")]} filters={NO_FILTERS} />);

    await userEvent.selectOptions(screen.getByLabelText("Status"), "talking");

    expect(router.get).toHaveBeenCalledWith("/opportunities", { status: "talking" }, VISIT_OPTIONS);
  });

  it("asks Rails to flip the sort direction", async () => {
    render(<Index opportunities={[build(1, "Acme Logistics")]} filters={NO_FILTERS} />);

    await userEvent.click(screen.getByRole("button", { name: /follow-up/i }));

    expect(router.get).toHaveBeenCalledWith("/opportunities", { dir: "desc" }, VISIT_OPTIONS);
  });

  it("keeps the sort direction when filters change or are cleared", async () => {
    render(
      <Index
        opportunities={[build(1, "Acme Logistics")]}
        filters={{ ...NO_FILTERS, status: "talking", dir: "desc" }}
      />,
    );

    await userEvent.click(screen.getByRole("button", { name: "Clear filters" }));

    expect(router.get).toHaveBeenCalledWith("/opportunities", { dir: "desc" }, VISIT_OPTIONS);
  });

  it("explains an empty result when filters are active", () => {
    render(<Index opportunities={[]} filters={{ ...NO_FILTERS, q: "zzz" }} />);

    expect(screen.getByText("No opportunities match these filters")).toBeInTheDocument();
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
  });

  it("shows a first-run empty state when there are no opportunities at all", () => {
    render(<Index opportunities={[]} filters={NO_FILTERS} />);

    expect(screen.getByText("No opportunities yet")).toBeInTheDocument();
  });

  it("links to the new opportunity form", () => {
    render(<Index opportunities={[]} filters={NO_FILTERS} />);

    expect(screen.getByRole("link", { name: "New opportunity" })).toHaveAttribute(
      "href",
      "/opportunities/new",
    );
  });
});
