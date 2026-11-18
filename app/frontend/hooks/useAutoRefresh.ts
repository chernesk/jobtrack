import { router } from "@inertiajs/react";
import { useEffect } from "react";

export const REFRESH_INTERVAL_MS = 15_000;

// Changes made elsewhere (the MCP server, another tab) reach the database but not an
// open page, because Inertia pages only show the props they loaded. This re-fetches
// the page's props on a timer, and only while the tab is visible: a background tab
// makes no requests, and coming back to the tab refreshes right away.
//
// `paused` is for a page holding UI state that fresh props would trample (the board
// mid-drag). `async` keeps a poll from cancelling a navigation the user just started,
// and `except: ["flash"]` stops a poll from wiping a flash message that is still showing.
// A failed poll (the record was deleted elsewhere, the server restarted) is ignored: the
// page just stays as it was, instead of an error modal appearing out of nowhere.
export function useAutoRefresh({ paused = false, intervalMs = REFRESH_INTERVAL_MS } = {}) {
  useEffect(() => {
    if (paused) return;

    const refresh = () => {
      if (document.visibilityState !== "visible") return;
      router.reload({
        async: true,
        except: ["flash"],
        onHttpException: () => false,
        onNetworkError: () => false,
      });
    };

    const timer = window.setInterval(refresh, intervalMs);
    document.addEventListener("visibilitychange", refresh);
    return () => {
      window.clearInterval(timer);
      document.removeEventListener("visibilitychange", refresh);
    };
  }, [paused, intervalMs]);
}
