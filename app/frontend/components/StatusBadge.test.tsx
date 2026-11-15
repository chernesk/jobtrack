import { render, screen } from "@testing-library/react";

import { STATUS_LABELS } from "../lib/labels";
import { STATUSES } from "../types";
import StatusBadge from "./StatusBadge";

describe("StatusBadge", () => {
  it.each(STATUSES)("shows a readable label for %s", (status) => {
    render(<StatusBadge status={status} />);

    expect(screen.getByText(STATUS_LABELS[status])).toBeInTheDocument();
  });
});
