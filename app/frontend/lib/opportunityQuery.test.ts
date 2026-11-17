import { DEFAULT_QUERY, hasActiveFilters, toParams } from "./opportunityQuery";

describe("toParams", () => {
  it("is empty for the default query so URLs stay clean", () => {
    expect(toParams(DEFAULT_QUERY)).toEqual({});
  });

  it("includes only the filters that are set", () => {
    expect(
      toParams({ q: "acme", status: "talking", kind: "", dir: "asc", archived: false }),
    ).toEqual({
      q: "acme",
      status: "talking",
    });
  });

  it("includes archived only when it is on", () => {
    expect(toParams({ ...DEFAULT_QUERY, archived: true })).toEqual({ archived: "1" });
  });

  it("includes the sort direction only when it isn't the default", () => {
    expect(toParams({ ...DEFAULT_QUERY, dir: "desc" })).toEqual({ dir: "desc" });
  });
});

describe("hasActiveFilters", () => {
  it("ignores sort direction", () => {
    expect(hasActiveFilters({ ...DEFAULT_QUERY, dir: "desc" })).toBe(false);
  });

  it.each([
    { q: "x" },
    { status: "offer" as const },
    { kind: "full_time" as const },
    { archived: true },
  ])("is true when %o is set", (override) => {
    expect(hasActiveFilters({ ...DEFAULT_QUERY, ...override })).toBe(true);
  });
});
