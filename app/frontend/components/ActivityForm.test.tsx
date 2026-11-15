import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useState } from "react";
import { beforeEach, vi } from "vitest";

import ActivityForm from "./ActivityForm";

// Stand-in for Inertia's `useForm` (the real hook needs a running Inertia app):
// real state for data and errors, spies for the request. `post` is told to run
// `onSuccess` so we can check the form resets after a save.
const post = vi.fn();
let transformed: unknown;

vi.mock("@inertiajs/react", () => ({
  useForm: <T extends Record<string, unknown>>(initial: T) => {
    const [data, setDataState] = useState(initial);
    const [errors, setErrors] = useState<Record<string, string>>({});
    return {
      data,
      errors,
      processing: false,
      setData: (key: string, value: unknown) => setDataState((d) => ({ ...d, [key]: value })),
      setError: (key: string, message: string) => setErrors({ [key]: message }),
      clearErrors: () => setErrors({}),
      reset: (...fields: string[]) =>
        setDataState((d) => ({ ...d, ...Object.fromEntries(fields.map((f) => [f, initial[f]])) })),
      transform: (callback: (values: T) => unknown) => {
        transformed = callback(data);
      },
      post: (url: string, options?: { onSuccess?: () => void }) => {
        post(url, options);
        options?.onSuccess?.();
      },
    };
  },
}));

describe("ActivityForm", () => {
  beforeEach(() => {
    post.mockClear();
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date(2026, 10, 14, 12));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("defaults to an email today", () => {
    render(<ActivityForm opportunityId={3} />);

    expect(screen.getByLabelText("Activity type")).toHaveValue("email");
    expect(screen.getByLabelText("Date")).toHaveValue("2026-11-14");
  });

  it("asks for a description instead of sending an empty activity", async () => {
    render(<ActivityForm opportunityId={3} />);

    await userEvent.click(screen.getByRole("button", { name: "Add activity" }));

    expect(screen.getByLabelText("What happened")).toHaveAccessibleDescription(
      "Add a note about what happened",
    );
    expect(post).not.toHaveBeenCalled();
  });

  it("posts to the opportunity's activities, then clears the text but keeps type and date", async () => {
    render(<ActivityForm opportunityId={3} />);

    await userEvent.selectOptions(screen.getByLabelText("Activity type"), "Call");
    await userEvent.type(screen.getByLabelText("What happened"), "Intro call");
    await userEvent.click(screen.getByRole("button", { name: "Add activity" }));

    expect(post).toHaveBeenCalledWith(
      "/opportunities/3/activities",
      expect.objectContaining({ preserveScroll: true }),
    );
    expect(transformed).toMatchObject({ activity: { kind: "call" } });
    expect(screen.getByLabelText("What happened")).toHaveValue("");
    expect(screen.getByLabelText("Activity type")).toHaveValue("call");
    expect(screen.getByLabelText("Date")).toHaveValue("2026-11-14");
  });
});
