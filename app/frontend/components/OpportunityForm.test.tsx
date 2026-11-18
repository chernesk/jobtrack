import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useState, type AnchorHTMLAttributes } from "react";
import { beforeEach, vi } from "vitest";

import type { Opportunity } from "../types";
import OpportunityForm from "./OpportunityForm";

// A minimal stand-in for Inertia's `useForm`: real state for data and errors,
// spies for the requests. The real hook needs a running Inertia app, so this keeps
// the test about what the user sees. Server errors are injected via `serverErrors`.
const post = vi.fn();
const patch = vi.fn();
let serverErrors: Record<string, string> = {};
let transformed: unknown;

vi.mock("@inertiajs/react", () => ({
  Link: (props: AnchorHTMLAttributes<HTMLAnchorElement>) => <a {...props} />,
  useForm: <T extends Record<string, unknown>>(initial: T) => {
    const [data, setDataState] = useState(initial);
    const [errors, setErrors] = useState<Record<string, string>>(serverErrors);
    return {
      data,
      errors,
      processing: false,
      setData: (key: string, value: unknown) => setDataState((d) => ({ ...d, [key]: value })),
      setError: (next: Record<string, string>) => setErrors(next),
      clearErrors: () => setErrors({}),
      transform: (callback: (values: T) => unknown) => {
        transformed = callback(data);
      },
      post,
      patch,
    };
  },
}));

const EXISTING: Opportunity = {
  id: 7,
  company: "Northwind Health",
  role: "Rails Engineer",
  kind: "contract_w2",
  source: null,
  status: "talking",
  pay_min: 90,
  pay_max: 110,
  pay_unit: "hourly",
  url: null,
  contacted_on: null,
  follow_up_on: "2026-11-20",
  notes: "Spoke with the hiring manager",
  position: 1,
  closed_reason: null,
  archived_at: null,
  external_id: null,
  last_verified_on: null,
  resume_version: null,
  contact_name: null,
  application_channel: null,
};

describe("OpportunityForm", () => {
  beforeEach(() => {
    post.mockClear();
    patch.mockClear();
    serverErrors = {};
  });

  it("shows required-field errors and sends nothing when company and role are empty", async () => {
    render(<OpportunityForm />);

    await userEvent.click(screen.getByRole("button", { name: "Add opportunity" }));

    expect(screen.getByLabelText("Company")).toHaveAccessibleDescription("Company is required");
    expect(screen.getByLabelText("Role")).toHaveAccessibleDescription("Role is required");
    expect(post).not.toHaveBeenCalled();
  });

  it("posts a new opportunity when the required fields are filled", async () => {
    render(<OpportunityForm />);

    await userEvent.type(screen.getByLabelText("Company"), "Acme Logistics");
    await userEvent.type(screen.getByLabelText("Role"), "Rails Engineer");
    await userEvent.selectOptions(screen.getByLabelText("Status"), "Contacted");
    await userEvent.click(screen.getByRole("button", { name: "Add opportunity" }));

    expect(post).toHaveBeenCalledWith("/opportunities");
    expect(patch).not.toHaveBeenCalled();
    expect(screen.queryByRole("alert")).not.toBeInTheDocument();
  });

  it("fills the posting id and verified date when editing", () => {
    render(
      <OpportunityForm
        opportunity={{ ...EXISTING, external_id: "42472", last_verified_on: "2026-11-17" }}
      />,
    );

    expect(screen.getByLabelText("Posting ID")).toHaveValue("42472");
    expect(screen.getByLabelText("Posting last verified")).toHaveValue("2026-11-17");
  });

  it("fills the application details when editing", () => {
    render(
      <OpportunityForm
        opportunity={{
          ...EXISTING,
          application_channel: "email",
          resume_version: "backend-v3",
          contact_name: "Dana Whitfield",
        }}
      />,
    );

    expect(screen.getByLabelText("Applied via")).toHaveValue("email");
    expect(screen.getByLabelText("Resume version")).toHaveValue("backend-v3");
    expect(screen.getByLabelText("Contact person")).toHaveValue("Dana Whitfield");
  });

  it("asks why it closed only when the status is closed", () => {
    const { unmount } = render(<OpportunityForm opportunity={EXISTING} />);
    expect(screen.queryByLabelText("Why did it close?")).not.toBeInTheDocument();
    unmount();

    render(
      <OpportunityForm
        opportunity={{ ...EXISTING, status: "closed", closed_reason: "withdrew" }}
      />,
    );
    expect(screen.getByLabelText("Why did it close?")).toHaveValue("withdrew");
  });

  it("wraps the data under `opportunity` as the Rails controller expects", () => {
    render(<OpportunityForm />);

    expect(transformed).toMatchObject({ opportunity: { company: "", status: "not_contacted" } });
  });

  it("fills the form from the record and patches it when editing", async () => {
    render(<OpportunityForm opportunity={EXISTING} />);

    expect(screen.getByLabelText("Company")).toHaveValue("Northwind Health");
    expect(screen.getByLabelText("Type")).toHaveValue("contract_w2");
    expect(screen.getByLabelText("Source")).toHaveValue("");
    expect(screen.getByLabelText("Minimum pay")).toHaveValue(90);
    expect(screen.getByLabelText("Follow up on")).toHaveValue("2026-11-20");

    await userEvent.clear(screen.getByLabelText("Company"));
    await userEvent.type(screen.getByLabelText("Company"), "Northwind Care");
    await userEvent.click(screen.getByRole("button", { name: "Save changes" }));

    expect(patch).toHaveBeenCalledWith("/opportunities/7");
    expect(post).not.toHaveBeenCalled();
  });

  it("shows server validation errors next to the matching field", () => {
    serverErrors = { pay_max: "must be greater than or equal to minimum pay" };

    render(<OpportunityForm opportunity={EXISTING} />);

    expect(screen.getByLabelText("Maximum pay")).toHaveAccessibleDescription(
      "must be greater than or equal to minimum pay",
    );
    expect(screen.getByLabelText("Maximum pay")).toBeInvalid();
    expect(screen.getByLabelText("Minimum pay")).toBeValid();
  });

  it("offers a way back to the list", () => {
    render(<OpportunityForm />);

    expect(screen.getByRole("link", { name: "Cancel" })).toHaveAttribute("href", "/opportunities");
  });
});
