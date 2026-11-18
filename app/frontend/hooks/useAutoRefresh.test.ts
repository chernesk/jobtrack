import { router } from "@inertiajs/react";
import { renderHook } from "@testing-library/react";
import { afterEach, beforeEach, vi } from "vitest";

import { REFRESH_INTERVAL_MS, useAutoRefresh } from "./useAutoRefresh";

vi.mock("@inertiajs/react", () => ({ router: { reload: vi.fn() } }));

function setVisibility(state: "visible" | "hidden") {
  Object.defineProperty(document, "visibilityState", { value: state, configurable: true });
}

beforeEach(() => {
  vi.useFakeTimers();
  setVisibility("visible");
});

afterEach(() => {
  vi.useRealTimers();
  vi.clearAllMocks();
});

describe("useAutoRefresh", () => {
  it("reloads the page props on each interval while the tab is visible", () => {
    renderHook(() => useAutoRefresh());

    vi.advanceTimersByTime(REFRESH_INTERVAL_MS * 2);

    expect(router.reload).toHaveBeenCalledTimes(2);
    expect(router.reload).toHaveBeenCalledWith(
      expect.objectContaining({ async: true, except: ["flash"] }),
    );
  });

  it("ignores a failed poll instead of letting Inertia show an error modal", () => {
    renderHook(() => useAutoRefresh());
    vi.advanceTimersByTime(REFRESH_INTERVAL_MS);

    const options = vi.mocked(router.reload).mock.calls[0]?.[0];

    // Returning false tells Inertia not to show its default error handling.
    expect(options?.onHttpException?.({} as never)).toBe(false);
    expect(options?.onNetworkError?.(new Error("offline"))).toBe(false);
  });

  it("makes no requests while the tab is hidden", () => {
    setVisibility("hidden");
    renderHook(() => useAutoRefresh());

    vi.advanceTimersByTime(REFRESH_INTERVAL_MS * 3);
    document.dispatchEvent(new Event("visibilitychange"));

    expect(router.reload).not.toHaveBeenCalled();
  });

  it("refreshes right away when the tab becomes visible again", () => {
    setVisibility("hidden");
    renderHook(() => useAutoRefresh());

    setVisibility("visible");
    document.dispatchEvent(new Event("visibilitychange"));

    expect(router.reload).toHaveBeenCalledTimes(1);
  });

  it("does nothing while paused", () => {
    renderHook(() => useAutoRefresh({ paused: true }));

    vi.advanceTimersByTime(REFRESH_INTERVAL_MS * 3);

    expect(router.reload).not.toHaveBeenCalled();
  });

  it("stops polling when the page unmounts", () => {
    const { unmount } = renderHook(() => useAutoRefresh());
    unmount();

    vi.advanceTimersByTime(REFRESH_INTERVAL_MS * 3);

    expect(router.reload).not.toHaveBeenCalled();
  });
});
