module JobTrackMcp
  module Tools
    class CreateOpportunity < Base
      tool_name "create_opportunity"
      description "Add a new opportunity. Only company and role are required. New opportunities start as not_contacted " \
                  "unless a status is given. Search first to avoid creating a duplicate."
      input_schema(properties: OPPORTUNITY_PROPERTIES, required: %w[company role])
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.call(server_context: nil, **attributes)
        attributes = clean(attributes)
        if (problem = check_dates(attributes))
          return failure(problem)
        end

        opportunity = Opportunity.new(attributes.slice(*Opportunity::EDITABLE_ATTRIBUTES))
        return validation_failure(opportunity) unless opportunity.save

        respond(opportunity.as_props)
      end
    end
  end
end
