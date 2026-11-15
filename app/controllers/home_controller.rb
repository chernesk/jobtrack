class HomeController < ApplicationController
  def index
    today = Date.current
    counts = Opportunity.group(:status).count

    render inertia: "Home/Index", props: {
      # `today` comes from the server so "overdue" never depends on the browser's clock or time zone.
      today: today.iso8601,
      counts: Opportunity::STATUSES.index_with { |status| counts.fetch(status, 0) },
      follow_ups_due: Opportunity.flagged_due.map(&:as_props),
      recent_activity: Activity.recent.map(&:as_feed_props)
    }
  end
end
