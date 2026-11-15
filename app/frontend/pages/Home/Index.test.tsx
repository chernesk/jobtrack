import { render, screen } from "@testing-library/react";
import type { AnchorHTMLAttributes } from "react";
import { vi } from "vitest";

import Index from "./Index";

vi.mock("@inertiajs/react", () => ({
  Link: (props: AnchorHTMLAttributes<HTMLAnchorElement>) => <a {...props} />,
  router: { delete: vi.fn() },
  usePage: () => ({
    url: "/",
    props: { auth: { user: { email_address: "demo@example.com" } }, flash: {} },
  }),
}));

describe("Home/Index", () => {
  it("greets the signed-in user inside the app layout", () => {
    render(<Index user={{ email_address: "demo@example.com" }} />);

    expect(screen.getByRole("heading", { name: /hello from react/i })).toBeInTheDocument();
    expect(screen.getByRole("navigation", { name: "Main" })).toBeInTheDocument();
  });
});
