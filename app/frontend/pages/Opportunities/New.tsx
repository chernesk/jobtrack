import Layout from "../../components/Layout";
import OpportunityForm from "../../components/OpportunityForm";

export default function New() {
  return (
    <Layout>
      <h1 className="text-2xl font-semibold">New opportunity</h1>
      <div className="mt-6">
        <OpportunityForm />
      </div>
    </Layout>
  );
}
