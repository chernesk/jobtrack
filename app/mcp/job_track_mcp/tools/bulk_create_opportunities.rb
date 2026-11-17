module JobTrackMcp
  module Tools
    class BulkCreateOpportunities < Base
      MAX = 25

      tool_name "bulk_create_opportunities"
      description "Add several opportunities in one call (up to #{MAX}), for example the matches from a daily search. " \
                  "Each item takes the same fields as create_opportunity. Every item is handled on its own: " \
                  "duplicates (same external_id or posting URL) are skipped and reported with the existing id, and a " \
                  "problem with one item does not stop the others. The result lists what happened to each, in order. " \
                  "A malformed item (for example an unknown status) rejects the whole call before anything is saved."
      input_schema(
        properties: {
          opportunities: {
            type: "array", minItems: 1, maxItems: MAX,
            items: { type: "object", properties: OPPORTUNITY_PROPERTIES, required: %w[company role] }
          }
        },
        required: [ "opportunities" ]
      )
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: false, open_world_hint: false)

      def self.call(opportunities:, server_context: nil)
        results = opportunities.each_with_index.map { |item, index| result_for(index, item) }

        respond(
          created: results.count { |r| r[:result] == "created" },
          duplicates: results.count { |r| r[:result] == "duplicate" },
          errors: results.count { |r| r[:result] == "error" },
          results: results
        )
      end

      def self.result_for(index, item)
        outcome, value = Opportunity.transaction(requires_new: true) { create_or_report(item) }

        case outcome
        when :created then { index: index, result: "created", id: value.id, company: value.company, role: value.role }
        when :duplicate then { index: index, result: "duplicate", id: value.id, message: duplicate_summary(value) }
        when :invalid then { index: index, result: "error", message: "Not saved: #{value.errors.full_messages.to_sentence}." }
        else { index: index, result: "error", message: value }
        end
      end
    end
  end
end
