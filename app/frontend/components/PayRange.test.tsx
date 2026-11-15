import { render, screen } from "@testing-library/react";

import PayRange, { formatPayRange } from "./PayRange";

describe("formatPayRange", () => {
  it("shows a yearly range", () => {
    expect(formatPayRange({ min: 150000, max: 180000, unit: "yearly" })).toBe("$150,000 – $180,000 / year");
  });

  it("shows an hourly range in the hourly unit", () => {
    expect(formatPayRange({ min: 95, max: 115, unit: "hourly" })).toBe("$95 – $115 / hour");
  });

  it("collapses an equal min and max into one amount", () => {
    expect(formatPayRange({ min: 100, max: 100, unit: "hourly" })).toBe("$100 / hour");
  });

  it("handles a single bound", () => {
    expect(formatPayRange({ min: 150000, max: null, unit: "yearly" })).toBe("$150,000+ / year");
    expect(formatPayRange({ min: null, max: 120, unit: "hourly" })).toBe("Up to $120 / hour");
  });

  it("says pay is not listed when there is no pay", () => {
    expect(formatPayRange({ min: null, max: null, unit: "yearly" })).toBe("Pay not listed");
  });
});

describe("PayRange", () => {
  it("renders the formatted range", () => {
    render(<PayRange min={85} max={100} unit="hourly" />);

    expect(screen.getByText("$85 – $100 / hour")).toBeInTheDocument();
  });
});
