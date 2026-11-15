import Layout from "../../components/Layout";
import OpportunityForm from "../../components/OpportunityForm";
import type { OpportunityEditProps } from "../../types";

export default function Edit({ opportunity }: OpportunityEditProps) {
  return (
    <Layout>
      <h1 className="text-2xl font-semibold">Edit {opportunity.company}</h1>
      <div className="mt-6">
        <OpportunityForm opportunity={opportunity} />
      </div>
    </Layout>
  );
}
