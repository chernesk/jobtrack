import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach } from "vitest";

import ThemeToggle from "./ThemeToggle";

afterEach(() => {
  document.documentElement.classList.remove("dark");
  localStorage.clear();
});

describe("ThemeToggle", () => {
  it("offers dark mode when the page is light, and switches and remembers it", async () => {
    render(<ThemeToggle />);

    await userEvent.click(screen.getByRole("button", { name: "Dark mode" }));

    expect(document.documentElement).toHaveClass("dark");
    expect(localStorage.getItem("theme")).toBe("dark");
    expect(screen.getByRole("button", { name: "Light mode" })).toBeInTheDocument();
  });

  it("starts from whatever theme the page already has", async () => {
    document.documentElement.classList.add("dark");
    render(<ThemeToggle />);

    await userEvent.click(screen.getByRole("button", { name: "Light mode" }));

    expect(document.documentElement).not.toHaveClass("dark");
    expect(localStorage.getItem("theme")).toBe("light");
  });
});
