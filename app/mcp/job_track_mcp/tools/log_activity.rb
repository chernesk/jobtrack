module JobTrackMcp
  module Tools
    class LogActivity < Base
      tool_name "log_activity"
      description "Record something that happened on an opportunity: an email, a call, an interview, or a note. " \
                  "Defaults to today. Use update_opportunity separately to change the status or follow-up date."
      input_schema(
        properties: {
          opportunity_id: { type: "integer", description: "Opportunity id" },
          kind: { type: "string", enum: ACTIVITY_KINDS },
          body: { type: "string", description: "What happened" },
          occurred_on: { type: "string", description: "When it happened (#{DATE_NOTE}); defaults to today" }
        },
        required: %w[opportunity_id kind body]
      )
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.call(opportunity_id:, kind:, body:, occurred_on: nil, server_context: nil)
        opportunity = Opportunity.find_by(id: opportunity_id) or return not_found(opportunity_id)
        if (problem = check_dates({ occurred_on: occurred_on }, [ :occurred_on ]))
          return failure(problem)
        end

        activity = opportunity.activities.build(kind: kind, body: body, occurred_on: occurred_on.presence || Date.current)
        return validation_failure(activity) unless activity.save

        respond(activity.as_props.merge("opportunity_id" => opportunity.id))
      end
    end
  end
end
