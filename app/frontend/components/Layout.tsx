import { Link, router, usePage } from "@inertiajs/react";
import type { ReactNode } from "react";

import type { SharedProps } from "../types";
import Button from "./Button";
import ThemeToggle from "./ThemeToggle";

const NAV_ITEMS = [
  { href: "/", label: "Dashboard" },
  { href: "/opportunities", label: "Opportunities" },
  { href: "/board", label: "Board" },
] as const;

function isActive(currentPath: string, href: string): boolean {
  return href === "/" ? currentPath === "/" : currentPath.startsWith(href);
}

interface LayoutProps {
  children: ReactNode;
  // Let the content use more of a wide screen (the board has six columns).
  wide?: boolean;
}

export default function Layout({ children, wide = false }: LayoutProps) {
  // Shared props come from `inertia_share` in ApplicationController, so every
  // page gets them without each controller passing them.
  const { url, props } = usePage<SharedProps>();
  const { auth, flash } = props;
  // `url` can include a query string ("/opportunities?status=talking").
  const path = url.split("?")[0] ?? url;

  return (
    <div className="min-h-screen">
      <header className="border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900">
        <nav
          aria-label="Main"
          className={`mx-auto flex items-center gap-6 px-6 py-3 ${wide ? "max-w-[96rem]" : "max-w-6xl"}`}
        >
          <span className="text-lg font-semibold">JobTrack</span>
          <ul className="flex flex-1 gap-4">
            {NAV_ITEMS.map((item) => (
              <li key={item.href}>
                <Link
                  href={item.href}
                  aria-current={isActive(path, item.href) ? "page" : undefined}
                  className={
                    isActive(path, item.href)
                      ? "font-medium text-slate-900 dark:text-slate-100"
                      : "text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-slate-100"
                  }
                >
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
          <ThemeToggle />
          {auth.user && (
            <div className="flex items-center gap-3 text-sm text-slate-600 dark:text-slate-400">
              <span>{auth.user.email_address}</span>
              <Button variant="secondary" onClick={() => router.delete("/session")}>
                Sign out
              </Button>
            </div>
          )}
        </nav>
      </header>

      <main className={`mx-auto px-6 py-8 ${wide ? "max-w-[96rem]" : "max-w-6xl"}`}>
        {flash.notice && (
          <p
            role="status"
            className="mb-4 rounded bg-emerald-50 dark:bg-emerald-950 px-4 py-2 text-sm text-emerald-800 dark:text-emerald-200"
          >
            {flash.notice}
          </p>
        )}
        {flash.alert && (
          <p
            role="alert"
            className="mb-4 rounded bg-red-50 dark:bg-red-950 px-4 py-2 text-sm text-red-800 dark:text-red-200"
          >
            {flash.alert}
          </p>
        )}
        {children}
      </main>
    </div>
  );
}
