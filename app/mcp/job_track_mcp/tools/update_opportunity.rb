module JobTrackMcp
  module Tools
    class UpdateOpportunity < Base
      # Moving to the bottom of a column: the model clamps any larger index.
      BOTTOM = 1_000_000
      REQUIRED_FIELDS = %i[company role status].freeze

      # Everything except company, role and status may be cleared by sending null.
      PROPERTIES = OPPORTUNITY_PROPERTIES.to_h do |name, schema|
        next [ name, schema ] if REQUIRED_FIELDS.include?(name)

        nullable = schema.merge(type: [ schema[:type], "null" ])
        nullable[:enum] = schema[:enum] + [ nil ] if schema[:enum]
        [ name, nullable ]
      end.freeze

      tool_name "update_opportunity"
      description "Change fields on an existing opportunity. Send only the fields to change; everything else is left alone. " \
                  "Changing status moves the card to the bottom of that column on the board. " \
                  "Send null to clear an optional field (everything except company, role and status)."
      input_schema(properties: { id: { type: "integer", description: "Opportunity id" } }.merge(PROPERTIES), required: [ "id" ])
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(id:, server_context: nil, **attributes)
        opportunity = Opportunity.find_by(id: id) or return not_found(id)
        attributes = clean(attributes).slice(*Opportunity::EDITABLE_ATTRIBUTES)
        if (problem = check_dates(attributes))
          return failure(problem)
        end

        new_status = attributes.delete(:status)
        opportunity.assign_attributes(attributes)
        return validation_failure(opportunity) unless opportunity.save

        if new_status && new_status != opportunity.status && !opportunity.move_to(new_status, BOTTOM)
          return validation_failure(opportunity)
        end

        respond(opportunity.reload.as_props)
      end
    end
  end
end
