module JobTrackMcp
  module Tools
    class GetOpportunity < Base
      tool_name "get_opportunity"
      description "Get one opportunity with its full activity history (emails, calls, interviews, notes), newest first."
      input_schema(properties: { id: { type: "integer", description: "Opportunity id" } }, required: [ "id" ])
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(id:, server_context: nil)
        opportunity = Opportunity.find_by(id: id) or return not_found(id)

        respond(opportunity.as_props.merge(
          "activities" => opportunity.activities.order(occurred_on: :desc, id: :desc).map(&:as_props)
        ))
      end
    end
  end
end
