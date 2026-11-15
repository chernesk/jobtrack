import { render, screen } from "@testing-library/react";

import EmptyState from "./EmptyState";

describe("EmptyState", () => {
  it("shows the title and optional description", () => {
    render(<EmptyState title="No opportunities yet" description="Add your first one." />);

    expect(screen.getByRole("heading", { name: "No opportunities yet" })).toBeInTheDocument();
    expect(screen.getByText("Add your first one.")).toBeInTheDocument();
  });

  it("renders an action when given one", () => {
    render(<EmptyState title="Nothing here" action={<button type="button">Add one</button>} />);

    expect(screen.getByRole("button", { name: "Add one" })).toBeInTheDocument();
  });

  it("omits the description and action when not given", () => {
    render(<EmptyState title="Nothing here" />);

    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });
});
