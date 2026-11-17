module JobTrackMcp
  module Tools
    class SearchOpportunities < Base
      LIMIT = 50

      tool_name "search_opportunities"
      description "List opportunities in the job search, soonest follow-up first. Filter by text (matches company or role), " \
                  "status, or kind. Archived opportunities are hidden unless include_archived is true. Returns up to #{LIMIT}. Call this first to find an opportunity's id."
      input_schema(
        properties: {
          query: { type: "string", description: "Text to look for in the company or role" },
          status: { type: "string", enum: STATUSES },
          kind: { type: "string", enum: KINDS },
          include_archived: { type: "boolean", description: "Also list archived opportunities (hidden by default)" }
        }
      )
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(query: nil, status: nil, kind: nil, include_archived: false, server_context: nil)
        scope = (include_archived ? Opportunity.all : Opportunity.active).search(query.to_s).with_status(status.to_s).with_kind(kind.to_s).by_follow_up
        total = scope.count
        respond(total: total, shown: [ total, LIMIT ].min, opportunities: scope.limit(LIMIT).map(&:as_props))
      end
    end
  end
end
