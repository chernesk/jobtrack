import Layout from "../../components/Layout";
import type { HomeIndexProps } from "../../types";

// Placeholder until the dashboard (T9) replaces it.
export default function Index({ user }: HomeIndexProps) {
  return (
    <Layout>
      <h1 className="text-3xl font-semibold">Hello from React</h1>
      <p className="mt-2 text-slate-600 dark:text-slate-400">
        Signed in as <span className="font-medium">{user.email_address}</span>
      </p>
    </Layout>
  );
}
