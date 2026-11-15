const formatter = new Intl.DateTimeFormat("en-US", { dateStyle: "medium", timeZone: "UTC" });

// Rails sends dates as "YYYY-MM-DD". `new Date("2026-11-14")` is midnight UTC, so
// formatting in UTC keeps the calendar day the same in every time zone (formatting
// in local time would show the previous day for anyone west of UTC).
export function formatDate(iso: string): string {
  return formatter.format(new Date(iso));
}

// Today's calendar date in the user's own time zone, as "YYYY-MM-DD" (what
// <input type="date"> uses). `toISOString()` would be UTC and could name tomorrow
// in the evening, so build it from the local parts instead.
export function todayISO(now: Date = new Date()): string {
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${now.getFullYear()}-${month}-${day}`;
}

const MS_PER_DAY = 24 * 60 * 60 * 1000;

// Whole calendar days from `from` to `to` ("YYYY-MM-DD" strings). Both parse as
// midnight UTC, so daylight-saving changes can't make a day 23 or 25 hours long.
export function daysBetween(from: string, to: string): number {
  return Math.round((new Date(to).getTime() - new Date(from).getTime()) / MS_PER_DAY);
}

// "Due today", "1 day overdue", "5 days overdue".
export function dueLabel(followUpOn: string, today: string): string {
  const overdue = daysBetween(followUpOn, today);
  if (overdue <= 0) return "Due today";
  return overdue === 1 ? "1 day overdue" : `${overdue} days overdue`;
}
