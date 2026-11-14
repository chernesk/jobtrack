import { router } from "@inertiajs/react";

import type { HomeIndexProps } from "../../types";

export default function Index({ user }: HomeIndexProps) {
  return (
    <main className="mx-auto max-w-2xl p-8">
      <h1 className="text-3xl font-semibold">Hello from React</h1>
      <p className="mt-2 text-slate-600">
        Signed in as <span className="font-medium">{user.email_address}</span>
      </p>
      <button
        type="button"
        className="mt-6 rounded bg-slate-900 px-4 py-2 text-white hover:bg-slate-700"
        onClick={() => router.delete("/session")}
      >
        Sign out
      </button>
    </main>
  );
}
