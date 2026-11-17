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

        # Move first, then apply the other fields, all or nothing: the closed reason is only kept
        # once the status is closed, and a failed field must not leave the card moved.
        new_status = attributes.delete(:status)
        saved = false
        Opportunity.transaction do
          moved = new_status.nil? || new_status == opportunity.status || opportunity.move_to(new_status, BOTTOM)
          saved = moved && opportunity.update(attributes)
          raise ActiveRecord::Rollback unless saved
        end
        return validation_failure(opportunity) unless saved

        respond(opportunity.reload.as_props)
      end
    end
  end
end
