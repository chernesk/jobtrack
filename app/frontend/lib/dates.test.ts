import { formatDate } from "./dates";

describe("formatDate", () => {
  it("formats an ISO date as a medium date", () => {
    expect(formatDate("2026-11-14")).toBe("Nov 14, 2026");
  });

  it("keeps the calendar day regardless of the machine's time zone", () => {
    expect(formatDate("2026-01-01")).toBe("Jan 1, 2026");
    expect(formatDate("2026-12-31")).toBe("Dec 31, 2026");
  });
});
