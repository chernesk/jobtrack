import { Link, router } from "@inertiajs/react";

import EmptyState from "../../components/EmptyState";
import Layout from "../../components/Layout";
import OpportunityFilters from "../../components/OpportunityFilters";
import OpportunityTable from "../../components/OpportunityTable";
import { DEFAULT_QUERY, hasActiveFilters, toParams } from "../../lib/opportunityQuery";
import type { OpportunitiesIndexProps, OpportunityQuery } from "../../types";

// Filters live in the URL (and so in Rails), not in React state: each change is a
// GET that Rails answers with fresh props. That keeps links shareable and the
// back button working, and there is no client-side filtering logic to keep in sync.
function visit(query: OpportunityQuery) {
  router.get("/opportunities", toParams(query), { preserveState: true, replace: true });
}

export default function Index({ opportunities, filters }: OpportunitiesIndexProps) {
  return (
    <Layout>
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold">Opportunities</h1>
        <Link
          href="/opportunities/new"
          className="rounded bg-slate-900 px-4 py-2 text-sm font-medium text-white hover:bg-slate-700 dark:bg-slate-100 dark:text-slate-900 dark:hover:bg-slate-300"
        >
          New opportunity
        </Link>
      </div>

      <div className="mt-6 space-y-6">
        <OpportunityFilters
          query={filters}
          onChange={visit}
          onClear={() => visit({ ...DEFAULT_QUERY, dir: filters.dir })}
        />

        {opportunities.length > 0 ? (
          <OpportunityTable
            opportunities={opportunities}
            sortDirection={filters.dir}
            onSortChange={(dir) => visit({ ...filters, dir })}
          />
        ) : hasActiveFilters(filters) ? (
          <EmptyState
            title="No opportunities match these filters"
            description="Try a different search or clear the filters."
          />
        ) : (
          <EmptyState
            title="No opportunities yet"
            description="Add your first one to start tracking."
          />
        )}
      </div>
    </Layout>
  );
}
