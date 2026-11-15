import { afterEach, vi } from "vitest";

import { applyTheme, currentTheme, storedTheme } from "./theme";

afterEach(() => {
  document.documentElement.classList.remove("dark");
  localStorage.clear();
  vi.restoreAllMocks();
});

describe("theme", () => {
  it("applies and remembers a theme", () => {
    applyTheme("dark");

    expect(document.documentElement).toHaveClass("dark");
    expect(currentTheme()).toBe("dark");
    expect(storedTheme()).toBe("dark");

    applyTheme("light");

    expect(document.documentElement).not.toHaveClass("dark");
    expect(storedTheme()).toBe("light");
  });

  it("ignores a stored value it does not recognise", () => {
    localStorage.setItem("theme", "sepia");

    expect(storedTheme()).toBeNull();
  });

  it("still applies the theme when storage is unavailable", () => {
    vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new Error("blocked");
    });
    vi.spyOn(Storage.prototype, "getItem").mockImplementation(() => {
      throw new Error("blocked");
    });

    expect(() => applyTheme("dark")).not.toThrow();
    expect(currentTheme()).toBe("dark");
    expect(storedTheme()).toBeNull();
  });
});
