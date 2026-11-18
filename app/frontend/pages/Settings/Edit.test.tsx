import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useState, type AnchorHTMLAttributes } from "react";
import { vi } from "vitest";

import type { Settings } from "../../types";
import Edit from "./Edit";

const patch = vi.fn();

// A small stand-in for Inertia's useForm that keeps real state, so typing and toggling work.
vi.mock("@inertiajs/react", () => ({
  Link: (props: AnchorHTMLAttributes<HTMLAnchorElement>) => <a {...props} />,
  router: { post: vi.fn(), delete: vi.fn() },
  useForm: <T extends object>(initial: T) => {
    const [data, setDataState] = useState(initial);
    return {
      data,
      errors: {},
      processing: false,
      setData: (key: keyof T, value: unknown) => setDataState((old) => ({ ...old, [key]: value })),
      transform: vi.fn(),
      patch,
    };
  },
  usePage: () => ({
    url: "/settings",
    props: {
      auth: { user: { email_address: "demo@example.com" } },
      flash: {},
      auto_refresh: { enabled: true, seconds: 15 },
    },
  }),
}));

const SETTINGS: Settings = {
  auto_refresh_enabled: true,
  auto_refresh_seconds: 15,
  notifications_enabled: true,
  notify_when_nothing_due: true,
  hide_names: false,
  ntfy_url: null,
  ntfy_topic: null,
  app_url: null,
  ntfy_token_saved: false,
  from_environment: {
    ntfy_url: false,
    ntfy_topic: false,
    ntfy_token: false,
    app_url: false,
    hide_names: false,
  },
};

function renderPage(overrides: Partial<Settings> = {}) {
  return render(<Edit settings={{ ...SETTINGS, ...overrides }} />);
}

afterEach(() => vi.clearAllMocks());

describe("Settings page", () => {
  it("shows the live-update and notification settings", () => {
    renderPage({ ntfy_topic: "my-topic" });

    expect(screen.getByRole("heading", { name: "Settings" })).toBeInTheDocument();
    expect(screen.getByLabelText(/^Refresh open pages automatically/)).toBeChecked();
    expect(screen.getByLabelText("Refresh every")).toHaveValue("15");
    expect(screen.getByLabelText("Send the daily notification")).toBeChecked();
    expect(screen.getByLabelText("Topic")).toHaveValue("my-topic");
  });

  it("disables the interval when refreshing is switched off", async () => {
    renderPage();

    await userEvent.click(screen.getByLabelText(/^Refresh open pages automatically/));

    expect(screen.getByLabelText("Refresh every")).toBeDisabled();
  });

  it("names the environment variable behind a blank field", () => {
    renderPage({ from_environment: { ...SETTINGS.from_environment, ntfy_topic: true } });

    expect(
      screen.getByText("Blank: using NTFY_TOPIC from the server environment."),
    ).toBeInTheDocument();
  });

  it("says a token is saved without showing it, and offers to remove it", () => {
    renderPage({ ntfy_token_saved: true });

    const token = screen.getByLabelText("Access token");
    expect(token).toHaveValue("");
    expect(token).toHaveAttribute("placeholder", "Saved. Leave blank to keep it.");
    expect(screen.getByLabelText("Remove the saved token")).not.toBeChecked();
  });

  it("only offers to remove a token when one is saved", () => {
    renderPage({ ntfy_token_saved: false });

    expect(screen.queryByLabelText("Remove the saved token")).not.toBeInTheDocument();
  });

  it("saves to /settings", async () => {
    renderPage();

    await userEvent.click(screen.getByRole("button", { name: "Save settings" }));

    expect(patch).toHaveBeenCalledWith("/settings", expect.any(Object));
  });

  it("sends a test notification", async () => {
    renderPage();

    await userEvent.click(screen.getByRole("button", { name: "Send a test notification" }));

    expect(router.post).toHaveBeenCalledWith("/settings/test");
  });
});
