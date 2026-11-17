module JobTrackMcp
  module Tools
    class PipelineSummary < Base
      tool_name "pipeline_summary"
      description "How many opportunities are in each status, plus how many have a follow-up due. A quick overview of the search."
      input_schema(properties: {})
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(server_context: nil)
        counts = Opportunity.group(:status).count
        respond(
          counts: STATUSES.index_with { |status| counts.fetch(status, 0) },
          follow_ups_due: Opportunity.follow_up_due.count
        )
      end
    end
  end
end
