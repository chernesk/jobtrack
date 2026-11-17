import { render } from "@testing-library/react";

import LogoMark from "./LogoMark";

describe("LogoMark", () => {
  it("is decorative, so it is hidden from assistive technology", () => {
    const { container } = render(<LogoMark />);

    expect(container.firstElementChild).toHaveAttribute("aria-hidden", "true");
  });

  it("accepts a size", () => {
    const { container } = render(<LogoMark className="h-12 w-12" />);

    expect(container.firstElementChild).toHaveClass("h-12", "w-12");
  });
});
