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

  def show
    opportunity = find_opportunity

    render inertia: "Opportunities/Show", props: {
      opportunity: opportunity.as_props,
      # Newest first; `id` breaks ties between activities on the same day.
      activities: opportunity.activities.order(occurred_on: :desc, id: :desc).map(&:as_props)
    }
  end

  def new
    render inertia: "Opportunities/New"
  end

  def create
    opportunity = Opportunity.new(opportunity_params)

    if opportunity.save
      redirect_to opportunity_path(opportunity), notice: "Opportunity added."
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
      redirect_to opportunity_path(opportunity), notice: "Opportunity updated."
    else
      redirect_to edit_opportunity_path(opportunity), inertia: { errors: first_errors(opportunity) }
    end
  end

  # Called by the board after a drag. `index` is the card's new 0-based place in the
  # column. Either way we redirect back to the board, so the client gets the
  # authoritative order (or the error, so it can undo its optimistic update).
  def move
    opportunity = find_opportunity
    status, index = params.expect(:status, :index)

    if opportunity.move_to(status.to_s, index.to_s.to_i)
      redirect_to board_path
    else
      redirect_to board_path, inertia: { errors: first_errors(opportunity) }
    end
  end

  private

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
    permitted = params.expect(opportunity: Opportunity::EDITABLE_ATTRIBUTES)
    Opportunity::NULLABLE_ENUMS.each { |name| permitted[name] = permitted[name].presence }
    permitted
  end
end
