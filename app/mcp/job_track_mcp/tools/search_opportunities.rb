module JobTrackMcp
  module Tools
    class SearchOpportunities < Base
      LIMIT = 50

      tool_name "search_opportunities"
      description "List opportunities in the job search, soonest follow-up first. Filter by text (matches company or role), " \
                  "status, or kind. Returns up to #{LIMIT}. Call this first to find an opportunity's id."
      input_schema(
        properties: {
          query: { type: "string", description: "Text to look for in the company or role" },
          status: { type: "string", enum: STATUSES },
          kind: { type: "string", enum: KINDS }
        }
      )
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(query: nil, status: nil, kind: nil, server_context: nil)
        scope = Opportunity.search(query.to_s).with_status(status.to_s).with_kind(kind.to_s).by_follow_up
        total = scope.count
        respond(total: total, shown: [ total, LIMIT ].min, opportunities: scope.limit(LIMIT).map(&:as_props))
      end
    end
  end
end
