class OpportunitiesController < ApplicationController
  def index
    # Query-string params arrive as strings (or, if someone tampers, arrays/hashes), so normalize first.
    query = params[:q].to_s.strip
    status = params[:status].to_s
    kind = params[:kind].to_s
    direction = params[:dir].to_s == "desc" ? "desc" : "asc"

    opportunities = Opportunity.search(query).with_status(status).with_kind(kind).by_follow_up(direction)

    render inertia: "Opportunities/Index", props: {
      opportunities: opportunities.map(&:as_props),
      # Echo the filters that were actually applied so the page controls match the results.
      filters: {
        q: query,
        status: Opportunity.statuses.key?(status) ? status : "",
        kind: Opportunity.kinds.key?(kind) ? kind : "",
        dir: direction
      }
    }
  end
end
