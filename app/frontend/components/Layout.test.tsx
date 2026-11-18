import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { AnchorHTMLAttributes } from "react";
import { vi } from "vitest";

import type { SharedProps } from "../types";
import Layout from "./Layout";

let page: { url: string; props: SharedProps };

// Layout reads shared props from Inertia's page context, which only exists
// inside a running Inertia app, so tests substitute a plain object.
vi.mock("@inertiajs/react", () => ({
  Link: (props: AnchorHTMLAttributes<HTMLAnchorElement>) => <a {...props} />,
  router: { delete: vi.fn() },
  usePage: () => page,
}));

function renderLayout(overrides: Partial<{ url: string; props: Partial<SharedProps> }> = {}) {
  page = {
    url: overrides.url ?? "/",
    props: {
      auth: { user: { email_address: "demo@example.com" } },
      flash: {},
      auto_refresh: { enabled: true, seconds: 15 },
      ...overrides.props,
    },
  };
  return render(<Layout>Page content</Layout>);
}

describe("Layout", () => {
  it("shows the JobTrack name as a link home", () => {
    renderLayout({ url: "/board" });

    expect(screen.getByRole("link", { name: "JobTrack" })).toHaveAttribute("href", "/");
  });

  it("renders the page content and the main navigation", () => {
    renderLayout();

    expect(screen.getByText("Page content")).toBeInTheDocument();
    const nav = screen.getByRole("navigation", { name: "Main" });
    expect(nav).toHaveTextContent("Dashboard");
    expect(screen.getByRole("link", { name: "Opportunities" })).toHaveAttribute(
      "href",
      "/opportunities",
    );
    expect(screen.getByRole("link", { name: "Board" })).toHaveAttribute("href", "/board");
  });

  it("marks the current section as the active page", () => {
    renderLayout({ url: "/opportunities?status=talking" });

    expect(screen.getByRole("link", { name: "Opportunities" })).toHaveAttribute(
      "aria-current",
      "page",
    );
    expect(screen.getByRole("link", { name: "Dashboard" })).not.toHaveAttribute("aria-current");
  });

  it("shows who is signed in and signs out", async () => {
    renderLayout();

    expect(screen.getByText("demo@example.com")).toBeInTheDocument();
    await userEvent.click(screen.getByRole("button", { name: "Sign out" }));

    expect(router.delete).toHaveBeenCalledWith("/session");
  });

  it("shows flash messages", () => {
    renderLayout({ props: { flash: { notice: "Saved.", alert: "Something broke." } } });

    expect(screen.getByRole("status")).toHaveTextContent("Saved.");
    expect(screen.getByRole("alert")).toHaveTextContent("Something broke.");
  });
});
