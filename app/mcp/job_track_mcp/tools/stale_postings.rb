module JobTrackMcp
  module Tools
    class StalePostings < Base
      LIMIT = 50

      tool_name "stale_postings"
      description "Postings that may have gone stale: opportunities still at recommended, not_contacted, contacted or applied " \
                  "whose last_verified_on is missing or older than the given number of days. Oldest first. After checking " \
                  "that a posting is still live, set last_verified_on with update_opportunity. Archived ones are not included."
      input_schema(
        properties: { days: { type: "integer", minimum: 0, description: "How many days old counts as stale (default 14)" } }
      )
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(days: 14, server_context: nil)
        today = Date.current
        scope = Opportunity.stale_postings(today - days)
        respond(today: today.iso8601, total: scope.count, opportunities: scope.limit(LIMIT).map(&:as_props))
      end
    end
  end
end
