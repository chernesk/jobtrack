import { router, usePage } from "@inertiajs/react";
import { useEffect } from "react";

import type { SharedProps } from "../types";

// Used until the server says otherwise (the Settings page sets these).
export const REFRESH_INTERVAL_MS = 15_000;

// Changes made elsewhere (the MCP server, another tab) reach the database but not an
// open page, because Inertia pages only show the props they loaded. This re-fetches
// the page's props on a timer, and only while the tab is visible: a background tab
// makes no requests, and coming back to the tab refreshes right away.
//
// Whether to poll, and how often, is a setting (Settings page), shared with every page.
// `paused` is for a page holding UI state that fresh props would trample (the board
// mid-drag). `async` keeps a poll from cancelling a navigation the user just started,
// and `except: ["flash"]` stops a poll from wiping a flash message that is still showing.
// A failed poll (the record was deleted elsewhere, the server restarted) is ignored: the
// page just stays as it was, instead of an error modal appearing out of nowhere.
export function useAutoRefresh({ paused = false } = {}) {
  const setting = usePage<SharedProps>().props.auto_refresh;
  const enabled = setting?.enabled ?? true;
  const intervalMs = setting ? setting.seconds * 1000 : REFRESH_INTERVAL_MS;

  useEffect(() => {
    if (paused || !enabled) return;

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
  }, [paused, enabled, intervalMs]);
}
