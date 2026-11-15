import { Link } from "@inertiajs/react";
import type { ReactNode } from "react";

import ActivityForm from "../../components/ActivityForm";
import ActivityTimeline from "../../components/ActivityTimeline";
import Layout from "../../components/Layout";
import PayRange from "../../components/PayRange";
import StatusBadge from "../../components/StatusBadge";
import { formatDate } from "../../lib/dates";
import { KIND_LABELS, SOURCE_LABELS } from "../../lib/labels";
import type { OpportunityShowProps } from "../../types";

// Only http(s) URLs become links. The value is user-entered text, and a
// `javascript:` URL in an href would run script when clicked.
function isWebUrl(value: string): boolean {
  return /^https?:\/\//i.test(value);
}

export default function Show({ opportunity, activities }: OpportunityShowProps) {
  const facts: { label: string; value: ReactNode }[] = [
    { label: "Type", value: opportunity.kind ? KIND_LABELS[opportunity.kind] : "—" },
    { label: "Source", value: opportunity.source ? SOURCE_LABELS[opportunity.source] : "—" },
    {
      label: "Pay",
      value: (
        <PayRange min={opportunity.pay_min} max={opportunity.pay_max} unit={opportunity.pay_unit} />
      ),
    },
    {
      label: "Contacted",
      value: opportunity.contacted_on ? formatDate(opportunity.contacted_on) : "—",
    },
    {
      label: "Follow up",
      value: opportunity.follow_up_on ? formatDate(opportunity.follow_up_on) : "—",
    },
    {
      label: "Posting",
      value:
        opportunity.url && isWebUrl(opportunity.url) ? (
          <a
            href={opportunity.url}
            target="_blank"
            rel="noopener noreferrer"
            className="text-indigo-700 underline"
          >
            View posting
          </a>
        ) : (
          (opportunity.url ?? "—")
        ),
    },
  ];

  return (
    <Layout>
      <Link href="/opportunities" className="text-sm text-slate-600 hover:text-slate-900">
        ← All opportunities
      </Link>

      <div className="mt-3 flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">{opportunity.company}</h1>
          <p className="mt-1 text-slate-600">{opportunity.role}</p>
        </div>
        <div className="flex items-center gap-3">
          <StatusBadge status={opportunity.status} />
          <Link
            href={`/opportunities/${opportunity.id}/edit`}
            className="rounded px-4 py-2 text-sm font-medium text-slate-900 ring-1 ring-inset ring-slate-300 hover:bg-slate-50"
          >
            Edit
          </Link>
        </div>
      </div>

      <dl className="mt-6 grid gap-x-8 gap-y-4 rounded-lg border border-slate-200 bg-white p-5 sm:grid-cols-3">
        {facts.map((fact) => (
          <div key={fact.label}>
            <dt className="text-xs font-semibold uppercase tracking-wide text-slate-500">
              {fact.label}
            </dt>
            <dd className="mt-1 text-sm text-slate-900">{fact.value}</dd>
          </div>
        ))}
      </dl>

      {opportunity.notes && (
        <section className="mt-6">
          <h2 className="text-base font-semibold">Notes</h2>
          <p className="mt-2 whitespace-pre-wrap text-sm text-slate-700">{opportunity.notes}</p>
        </section>
      )}

      <section className="mt-8">
        <h2 className="text-base font-semibold">Activity</h2>
        <div className="mt-4 grid gap-8 lg:grid-cols-2">
          <ActivityTimeline activities={activities} />
          <div className="rounded-lg border border-slate-200 bg-white p-5">
            <h3 className="mb-4 text-sm font-semibold">Add activity</h3>
            <ActivityForm opportunityId={opportunity.id} />
          </div>
        </div>
      </section>
    </Layout>
  );
}
