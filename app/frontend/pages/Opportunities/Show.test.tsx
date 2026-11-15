import { render, screen } from "@testing-library/react";
import type { AnchorHTMLAttributes } from "react";
import { vi } from "vitest";

import type { Opportunity } from "../../types";
import Show from "./Show";

vi.mock("@inertiajs/react", () => ({
  Link: (props: AnchorHTMLAttributes<HTMLAnchorElement>) => <a {...props} />,
  router: { get: vi.fn(), delete: vi.fn() },
  useForm: () => ({
    data: { kind: "email", occurred_on: "2026-11-14", body: "" },
    errors: {},
    processing: false,
    setData: vi.fn(),
    setError: vi.fn(),
    clearErrors: vi.fn(),
    reset: vi.fn(),
    transform: vi.fn(),
    post: vi.fn(),
  }),
  usePage: () => ({
    url: "/opportunities/7",
    props: { auth: { user: { email_address: "demo@example.com" } }, flash: {} },
  }),
}));

const OPPORTUNITY: Opportunity = {
  id: 7,
  company: "Northwind Health",
  role: "Rails Engineer",
  kind: "contract_w2",
  source: "recruiter",
  status: "interviewing",
  pay_min: 90,
  pay_max: 110,
  pay_unit: "hourly",
  url: "https://example.com/jobs/1",
  contacted_on: "2026-11-01",
  follow_up_on: "2026-11-20",
  notes: "Spoke with the hiring manager",
  position: 1,
};

describe("Opportunities/Show", () => {
  it("shows the opportunity's details, with pay in its own unit", () => {
    render(<Show opportunity={OPPORTUNITY} activities={[]} />);

    expect(screen.getByRole("heading", { name: "Northwind Health" })).toBeInTheDocument();
    expect(screen.getByText("Rails Engineer")).toBeInTheDocument();
    expect(screen.getByText("Interviewing")).toBeInTheDocument();
    expect(screen.getByText("Contract (W2)")).toBeInTheDocument();
    expect(screen.getByText("$90 – $110 / hour")).toBeInTheDocument();
    expect(screen.getByText("Nov 20, 2026")).toBeInTheDocument();
    expect(screen.getByText("Spoke with the hiring manager")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Edit" })).toHaveAttribute(
      "href",
      "/opportunities/7/edit",
    );
  });

  it("opens the posting safely in a new tab", () => {
    render(<Show opportunity={OPPORTUNITY} activities={[]} />);

    const link = screen.getByRole("link", { name: "View posting" });
    expect(link).toHaveAttribute("href", "https://example.com/jobs/1");
    expect(link).toHaveAttribute("rel", "noopener noreferrer");
  });

  it("does not turn a non-web URL into a link", () => {
    render(<Show opportunity={{ ...OPPORTUNITY, url: "javascript:alert(1)" }} activities={[]} />);

    expect(screen.queryByRole("link", { name: "View posting" })).not.toBeInTheDocument();
    expect(screen.getByText("javascript:alert(1)")).toBeInTheDocument();
  });

  it("shows the activity timeline and the add-activity form", () => {
    render(
      <Show
        opportunity={{ ...OPPORTUNITY, notes: null }}
        activities={[{ id: 1, kind: "call", occurred_on: "2026-11-10", body: "Intro call" }]}
      />,
    );

    expect(screen.getByText("Intro call")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Add activity" })).toBeInTheDocument();
    expect(screen.queryByRole("heading", { name: "Notes" })).not.toBeInTheDocument();
  });
});
