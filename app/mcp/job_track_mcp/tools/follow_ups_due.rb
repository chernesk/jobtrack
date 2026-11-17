module JobTrackMcp
  module Tools
    class FollowUpsDue < Base
      tool_name "follow_ups_due"
      description "Open opportunities whose follow-up date is today or earlier, most overdue first. " \
                  "Closed opportunities are not included."
      input_schema(properties: {})
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(server_context: nil)
        today = Date.current
        respond(today: today.iso8601, opportunities: Opportunity.follow_up_due(today).map(&:as_props))
      end
    end
  end
end
