module JobTrackMcp
  module Tools
    class ArchiveOpportunity < Base
      tool_name "archive_opportunity"
      description "Hide an opportunity from the board, lists and counts without deleting it (use this for entries made by " \
                  "mistake or duplicates). Nothing is lost: set archived to false to bring it back. " \
                  "For a real job that ended, set the status to closed with a closed_reason instead."
      input_schema(
        properties: {
          id: { type: "integer", description: "Opportunity id" },
          archived: { type: "boolean", description: "true (default) to archive, false to restore" }
        },
        required: [ "id" ]
      )
      annotations(read_only_hint: false, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      def self.call(id:, archived: true, server_context: nil)
        opportunity = Opportunity.find_by(id: id) or return not_found(id)

        archived ? opportunity.archive! : opportunity.unarchive!
        respond(opportunity.reload.as_props)
      end
    end
  end
end
