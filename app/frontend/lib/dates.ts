const formatter = new Intl.DateTimeFormat("en-US", { dateStyle: "medium", timeZone: "UTC" });

// Rails sends dates as "YYYY-MM-DD". `new Date("2026-11-14")` is midnight UTC, so
// formatting in UTC keeps the calendar day the same in every time zone (formatting
// in local time would show the previous day for anyone west of UTC).
export function formatDate(iso: string): string {
  return formatter.format(new Date(iso));
}
