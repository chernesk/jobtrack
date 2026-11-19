module JobTrackMcp
  module Tools
    class LogActivity < Base
      tool_name "log_activity"
      description "Record something that happened on an opportunity: an email, a call, an interview, or a note. " \
                  "Defaults to today. Pass follow_up_in_days to push the follow-up date to that many days from today in the same " \
                  "call (after a nudge, say). Use update_opportunity to change the status or set a specific date."
      input_schema(
        properties: {
          opportunity_id: { type: "integer", description: "Opportunity id" },
          kind: { type: "string", enum: ACTIVITY_KINDS },
          body: { type: "string", description: "What happened" },
          occurred_on: { type: "string", description: "When it happened (#{DATE_NOTE}); defaults to today" },
          follow_up_in_days: {
            type: "integer", minimum: 1, maximum: 365,
            description: "Also set the follow-up date to this many days from today"
          }
        },
        required: %w[opportunity_id kind body]
      )
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.call(opportunity_id:, kind:, body:, occurred_on: nil, follow_up_in_days: nil, server_context: nil)
        opportunity = Opportunity.find_by(id: opportunity_id) or return not_found(opportunity_id)
        if (problem = check_dates({ occurred_on: occurred_on }, [ :occurred_on ]))
          return failure(problem)
        end

        activity = opportunity.activities.build(kind: kind, body: body, occurred_on: occurred_on.presence || Date.current)
        return validation_failure(activity) unless save_with_follow_up(opportunity, activity, follow_up_in_days)

        payload = activity.as_props.merge("opportunity_id" => opportunity.id)
        payload["follow_up_on"] = opportunity.follow_up_on.iso8601 if follow_up_in_days
        respond(payload)
      end

      # The activity and the new follow-up date are saved together or not at all.
      def self.save_with_follow_up(opportunity, activity, days)
        Opportunity.transaction do
          opportunity.update!(follow_up_on: Date.current + days) if days
          activity.save || raise(ActiveRecord::Rollback)
        end
      rescue ActiveRecord::RecordInvalid
        activity.errors.add(:base, opportunity.errors.full_messages.to_sentence)
        false
      end
    end
  end
end
