import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, vi } from "vitest";

import { DEFAULT_QUERY } from "../lib/opportunityQuery";
import type { OpportunityQuery } from "../types";
import OpportunityFilters from "./OpportunityFilters";

const onChange = vi.fn();
const onClear = vi.fn();

function renderFilters(query: OpportunityQuery = DEFAULT_QUERY) {
  return render(<OpportunityFilters query={query} onChange={onChange} onClear={onClear} />);
}

function advance(ms: number) {
  return act(async () => {
    await vi.advanceTimersByTimeAsync(ms);
  });
}

describe("OpportunityFilters", () => {
  beforeEach(() => {
    // shouldAdvanceTime lets Testing Library's own internal timeouts still fire.
    vi.useFakeTimers({ shouldAdvanceTime: true });
    onChange.mockClear();
    onClear.mockClear();
  });
  afterEach(() => {
    vi.useRealTimers();
  });

  // `delay: null` stops user-event from waiting on timers, which are faked here.
  const user = () => userEvent.setup({ delay: null });

  it("reports a status change immediately", async () => {
    renderFilters();

    await user().selectOptions(screen.getByLabelText("Status"), "talking");

    expect(onChange).toHaveBeenCalledWith({ ...DEFAULT_QUERY, status: "talking" });
  });

  it("reports the archived-only toggle immediately", async () => {
    renderFilters();

    await user().click(screen.getByLabelText("Archived only"));

    expect(onChange).toHaveBeenCalledWith({ ...DEFAULT_QUERY, archived: true });
  });

  it("reports a type change immediately", async () => {
    renderFilters();

    await user().selectOptions(screen.getByLabelText("Type"), "contract_w2");

    expect(onChange).toHaveBeenCalledWith({ ...DEFAULT_QUERY, kind: "contract_w2" });
  });

  it("waits for a pause in typing before reporting the search", async () => {
    renderFilters();

    await user().type(screen.getByLabelText("Search"), "acme");
    expect(screen.getByLabelText("Search")).toHaveValue("acme");
    expect(onChange).not.toHaveBeenCalled();

    await advance(300);

    expect(onChange).toHaveBeenCalledTimes(1);
    expect(onChange).toHaveBeenCalledWith({ ...DEFAULT_QUERY, q: "acme" });
  });

  it("shows the current filter values", () => {
    renderFilters({
      q: "acme",
      status: "offer",
      kind: "contract_c2c",
      dir: "asc",
      archived: false,
    });

    expect(screen.getByLabelText("Search")).toHaveValue("acme");
    expect(screen.getByLabelText("Status")).toHaveValue("offer");
    expect(screen.getByLabelText("Type")).toHaveValue("contract_c2c");
  });

  it("resets the search box when the filters change from outside, e.g. back button", () => {
    const { rerender } = renderFilters({ ...DEFAULT_QUERY, q: "acme" });

    rerender(<OpportunityFilters query={DEFAULT_QUERY} onChange={onChange} onClear={onClear} />);

    expect(screen.getByLabelText("Search")).toHaveValue("");
    expect(onChange).not.toHaveBeenCalled();
  });

  it("doesn't overwrite what the user is still typing when an earlier search comes back", async () => {
    const { rerender } = renderFilters();
    const typist = user();

    await typist.type(screen.getByLabelText("Search"), "ac");
    await advance(300); // "ac" sent to the server
    await typist.type(screen.getByLabelText("Search"), "m"); // user keeps typing

    // the server's answer to "ac" arrives
    rerender(
      <OpportunityFilters
        query={{ ...DEFAULT_QUERY, q: "ac" }}
        onChange={onChange}
        onClear={onClear}
      />,
    );

    expect(screen.getByLabelText("Search")).toHaveValue("acm");
  });

  it("offers to clear filters only when some are active", async () => {
    const { rerender } = renderFilters();
    expect(screen.queryByRole("button", { name: "Clear filters" })).not.toBeInTheDocument();

    rerender(
      <OpportunityFilters
        query={{ ...DEFAULT_QUERY, status: "talking" }}
        onChange={onChange}
        onClear={onClear}
      />,
    );
    await user().click(screen.getByRole("button", { name: "Clear filters" }));

    expect(onClear).toHaveBeenCalledOnce();
  });
});
