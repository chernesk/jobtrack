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

  def new
    render inertia: "Opportunities/New"
  end

  def create
    opportunity = Opportunity.new(opportunity_params)

    if opportunity.save
      redirect_to opportunities_path, notice: "Opportunity added."
    else
      # Validation errors travel in the redirect; the form re-renders with them
      # next to the matching fields and keeps what the user typed.
      redirect_to new_opportunity_path, inertia: { errors: first_errors(opportunity) }
    end
  end

  def edit
    render inertia: "Opportunities/Edit", props: { opportunity: find_opportunity.as_props }
  end

  def update
    opportunity = find_opportunity

    if opportunity.update(opportunity_params)
      redirect_to opportunities_path, notice: "Opportunity updated."
    else
      redirect_to edit_opportunity_path(opportunity), inertia: { errors: first_errors(opportunity) }
    end
  end

  private

  EDITABLE_ATTRIBUTES = %i[
    company role kind source status pay_min pay_max pay_unit url contacted_on follow_up_on notes
  ].freeze
  NULLABLE_ENUMS = %w[kind source pay_unit].freeze

  # One message per field keeps the client type simple (`errors.company: string`).
  def first_errors(record)
    record.errors.to_hash.transform_values(&:first)
  end

  def find_opportunity
    Opportunity.find(params[:id])
  end

  # An empty <select> submits "", which the enums would reject. Treat it as "not chosen".
  # `position` is deliberately not editable here; the board owns ordering.
  def opportunity_params
    permitted = params.expect(opportunity: EDITABLE_ATTRIBUTES)
    NULLABLE_ENUMS.each { |name| permitted[name] = permitted[name].presence }
    permitted
  end
end
