import { createInertiaApp } from "@inertiajs/react";
import type { ComponentType } from "react";
import { createRoot } from "react-dom/client";

type PageModule = { default: ComponentType };

// Vite eagerly bundles every file under pages/, so a page named by a Rails
// controller (e.g. "Home/Index") resolves to app/frontend/pages/Home/Index.tsx.
// Test files live next to their pages, so they must be excluded or Vitest code
// ends up in the browser bundle and crashes the app on load.
const pages = import.meta.glob<PageModule>(["../pages/**/*.tsx", "!../pages/**/*.test.tsx"], {
  eager: true,
});

void createInertiaApp({
  resolve: (name) => {
    const page = pages[`../pages/${name}.tsx`];
    if (!page) {
      throw new Error(`Inertia page not found: ${name}`);
    }
    return page.default;
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />);
  },
});
