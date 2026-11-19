module JobTrackMcp
  module Tools
    class CreateOpportunity < Base
      tool_name "create_opportunity"
      description "Add a new opportunity. Only company and role are required. New opportunities start as not_contacted " \
                  "unless a status is given. Pass external_id (the job board's id) and url when you have them: an " \
                  "opportunity with the same external_id or posting URL is reported as a duplicate instead of being added again, " \
                  "and so is one with the same company and role (pass allow_duplicate: true if it really is a separate " \
                  "opening). Another role at a company already in the tracker is added, with a warning."
      input_schema(properties: OPPORTUNITY_PROPERTIES.merge(allow_duplicate: ALLOW_DUPLICATE), required: %w[company role])
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.call(server_context: nil, **attributes)
        outcome, value = create_or_report(attributes)

        case outcome
        when :created then respond(created_payload(value))
        when :duplicate then failure(duplicate_summary(value))
        when :similar then failure(similar_summary(value))
        when :invalid then validation_failure(value)
        else failure(value)
        end
      end

      def self.created_payload(opportunity)
        warning = company_warning(opportunity)
        warning ? opportunity.as_props.merge("warning" => warning) : opportunity.as_props
      end
    end
  end
end
