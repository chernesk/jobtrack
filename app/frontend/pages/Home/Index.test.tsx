import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { vi } from "vitest";

import Index from "./Index";

vi.mock("@inertiajs/react", () => ({
  router: { delete: vi.fn() },
}));

describe("Home/Index", () => {
  it("greets the signed-in user", () => {
    render(<Index user={{ email_address: "demo@example.com" }} />);

    expect(screen.getByRole("heading", { name: /hello from react/i })).toBeInTheDocument();
    expect(screen.getByText("demo@example.com")).toBeInTheDocument();
  });

  it("signs out when the button is clicked", async () => {
    render(<Index user={{ email_address: "demo@example.com" }} />);

    await userEvent.click(screen.getByRole("button", { name: /sign out/i }));

    expect(router.delete).toHaveBeenCalledWith("/session");
  });
});
