import FollowUpsDue from "../../components/FollowUpsDue";
import Layout from "../../components/Layout";
import RecentActivity from "../../components/RecentActivity";
import StatusCounts from "../../components/StatusCounts";
import type { HomeIndexProps } from "../../types";

export default function Index({ today, counts, follow_ups_due, recent_activity }: HomeIndexProps) {
  return (
    <Layout>
      <h1 className="text-2xl font-semibold">Dashboard</h1>

      <div className="mt-6 space-y-8">
        <StatusCounts counts={counts} />

        <div className="grid gap-8 lg:grid-cols-2">
          <section aria-labelledby="follow-ups-heading">
            <h2 id="follow-ups-heading" className="mb-3 text-base font-semibold">
              Follow-ups due
            </h2>
            <FollowUpsDue opportunities={follow_ups_due} today={today} />
          </section>

          <section aria-labelledby="recent-heading">
            <h2 id="recent-heading" className="mb-3 text-base font-semibold">
              Recent activity
            </h2>
            <RecentActivity activities={recent_activity} />
          </section>
        </div>
      </div>
    </Layout>
  );
}
