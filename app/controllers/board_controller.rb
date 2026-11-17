class BoardController < ApplicationController
  def show
    # The page groups cards into columns by status; within a status the order is `position`.
    render inertia: "Board/Show", props: { opportunities: Opportunity.active.order(:position, :id).map(&:as_props) }
  end
end
