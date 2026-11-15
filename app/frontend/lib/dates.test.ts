import { daysBetween, dueLabel, formatDate, todayISO } from "./dates";

describe("formatDate", () => {
  it("formats an ISO date as a medium date", () => {
    expect(formatDate("2026-11-14")).toBe("Nov 14, 2026");
  });

  it("keeps the calendar day regardless of the machine's time zone", () => {
    expect(formatDate("2026-01-01")).toBe("Jan 1, 2026");
    expect(formatDate("2026-12-31")).toBe("Dec 31, 2026");
  });
});

describe("todayISO", () => {
  it("uses the local calendar date, zero-padded", () => {
    expect(todayISO(new Date(2026, 0, 5, 23, 30))).toBe("2026-01-05");
    expect(todayISO(new Date(2026, 10, 14, 0, 5))).toBe("2026-11-14");
  });
});

describe("daysBetween", () => {
  it("counts calendar days, across month ends and daylight-saving changes", () => {
    expect(daysBetween("2026-11-10", "2026-11-15")).toBe(5);
    expect(daysBetween("2026-10-30", "2026-11-02")).toBe(3);
    expect(daysBetween("2026-03-07", "2026-03-09")).toBe(2);
    expect(daysBetween("2026-11-15", "2026-11-10")).toBe(-5);
  });
});

describe("dueLabel", () => {
  it("says how overdue a follow-up is", () => {
    expect(dueLabel("2026-11-15", "2026-11-15")).toBe("Due today");
    expect(dueLabel("2026-11-14", "2026-11-15")).toBe("1 day overdue");
    expect(dueLabel("2026-11-10", "2026-11-15")).toBe("5 days overdue");
  });
});
