import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { AnchorHTMLAttributes } from "react";
import { vi } from "vitest";

import { router } from "@inertiajs/react";
import type { Opportunity } from "../../types";
import Show from "./Show";

vi.mock("@inertiajs/react", () => ({
  Link: (props: AnchorHTMLAttributes<HTMLAnchorElement>) => <a {...props} />,
  router: { get: vi.fn(), delete: vi.fn(), patch: vi.fn() },
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
  closed_reason: null,
  archived_at: null,
  external_id: null,
  last_verified_on: null,
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

  it("shows the posting id and when the posting was last verified", () => {
    const { unmount } = render(<Show opportunity={OPPORTUNITY} activities={[]} />);
    expect(screen.getByText("Not yet")).toBeInTheDocument();
    unmount();

    render(
      <Show
        opportunity={{ ...OPPORTUNITY, external_id: "42472", last_verified_on: "2026-11-17" }}
        activities={[]}
      />,
    );
    expect(screen.getByText("42472")).toBeInTheDocument();
    expect(screen.getByText("Nov 17, 2026")).toBeInTheDocument();
  });

  it("shows why a closed opportunity closed", () => {
    render(
      <Show
        opportunity={{ ...OPPORTUNITY, status: "closed", closed_reason: "posting_closed" }}
        activities={[]}
      />,
    );

    expect(screen.getByText("Closed because")).toBeInTheDocument();
    expect(screen.getByText("Posting closed")).toBeInTheDocument();
  });

  it("archives with one click, and offers restore once archived", async () => {
    const { unmount } = render(<Show opportunity={OPPORTUNITY} activities={[]} />);

    await userEvent.click(screen.getByRole("button", { name: "Archive" }));
    expect(router.patch).toHaveBeenCalledWith("/opportunities/7/archive");
    unmount();

    render(
      <Show
        opportunity={{ ...OPPORTUNITY, archived_at: "2026-11-17T12:00:00Z" }}
        activities={[]}
      />,
    );
    expect(screen.getByRole("status")).toHaveTextContent("Archived Nov 17, 2026");
    await userEvent.click(screen.getByRole("button", { name: "Restore" }));
    expect(router.patch).toHaveBeenCalledWith("/opportunities/7/restore");
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
