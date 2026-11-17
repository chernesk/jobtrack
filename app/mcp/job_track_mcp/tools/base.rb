module JobTrackMcp
  module Tools
    # Shared helpers for the tools. Every tool returns JSON text (what a model reads best),
    # and reports problems as a tool error with a message the model can act on, instead
    # of raising, so a bad argument never becomes a protocol-level failure.
    class Base < MCP::Tool
      STATUSES = Opportunity::STATUSES
      KINDS = Opportunity.kinds.keys.freeze
      SOURCES = Opportunity.sources.keys.freeze
      PAY_UNITS = Opportunity.pay_units.keys.freeze
      ACTIVITY_KINDS = Activity.kinds.keys.freeze
      DATE_NOTE = "ISO 8601 date, YYYY-MM-DD".freeze

      # Properties shared by create and update (the fields a person can edit).
      OPPORTUNITY_PROPERTIES = {
        company: { type: "string", description: "Company name" },
        role: { type: "string", description: "Job title" },
        kind: { type: "string", enum: KINDS, description: "Type of work" },
        source: { type: "string", enum: SOURCES, description: "How the opportunity was found" },
        status: { type: "string", enum: STATUSES, description: "Where it is in the process" },
        pay_min: { type: "integer", minimum: 0, description: "Lowest pay, whole dollars" },
        pay_max: { type: "integer", minimum: 0, description: "Highest pay, whole dollars" },
        pay_unit: { type: "string", enum: PAY_UNITS, description: "Whether pay is per hour or per year" },
        url: { type: "string", description: "Link to the posting" },
        contacted_on: { type: "string", description: "Date first contacted (#{DATE_NOTE})" },
        follow_up_on: { type: "string", description: "Date to follow up (#{DATE_NOTE})" },
        notes: { type: "string", description: "Free-form notes" }
      }.freeze
      DATE_FIELDS = %i[contacted_on follow_up_on].freeze

      class << self
        def respond(payload)
          MCP::Tool::Response.new([ { type: "text", text: JSON.pretty_generate(payload) } ])
        end

        def failure(message)
          MCP::Tool::Response.new([ { type: "text", text: message } ], error: true)
        end

        def validation_failure(record)
          failure("Not saved: #{record.errors.full_messages.to_sentence}.")
        end

        def not_found(id)
          failure("No opportunity with id #{id}. Use search_opportunities to find the right id.")
        end

        # Dates arrive as strings. ActiveRecord would turn a malformed one into nil without a
        # word, so check them here and say what was wrong.
        def check_dates(attributes, fields = DATE_FIELDS)
          fields.each do |field|
            value = attributes[field]
            next if value.nil? || value == ""

            Date.iso8601(value.to_s)
          rescue Date::Error
            return "#{field} must be a date like 2026-12-31, got #{value.inspect}."
          end
          nil
        end

        # Optional enums arrive as "" when the model means "unset".
        def clean(attributes)
          attributes.transform_values { |value| value == "" ? nil : value }
        end
      end
    end
  end
end
