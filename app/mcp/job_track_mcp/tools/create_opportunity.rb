module JobTrackMcp
  module Tools
    class CreateOpportunity < Base
      tool_name "create_opportunity"
      description "Add a new opportunity. Only company and role are required. New opportunities start as not_contacted " \
                  "unless a status is given. Pass external_id (the job board's id) and url when you have them: an " \
                  "opportunity with the same external_id or posting URL is reported as a duplicate instead of being added again."
      input_schema(properties: OPPORTUNITY_PROPERTIES, required: %w[company role])
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.call(server_context: nil, **attributes)
        outcome, value = create_or_report(attributes)

        case outcome
        when :created then respond(value.as_props)
        when :duplicate then failure(duplicate_summary(value))
        when :invalid then validation_failure(value)
        else failure(value)
        end
      end
    end
  end
end
