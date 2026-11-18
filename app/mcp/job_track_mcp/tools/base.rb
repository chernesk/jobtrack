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
      CLOSED_REASONS = Opportunity.closed_reasons.keys.freeze
      APPLICATION_CHANNELS = Opportunity.application_channels.keys.freeze
      ACTIVITY_KINDS = Activity.kinds.keys.freeze
      DATE_NOTE = "ISO 8601 date, YYYY-MM-DD".freeze

      # Properties shared by create and update (the fields a person can edit).
      OPPORTUNITY_PROPERTIES = {
        company: { type: "string", description: "Company name" },
        role: { type: "string", description: "Job title" },
        kind: { type: "string", enum: KINDS, description: "Type of work" },
        source: { type: "string", enum: SOURCES, description: "How the opportunity was found" },
        status: { type: "string", enum: STATUSES, description: "Where it is in the process" },
        closed_reason: { type: "string", enum: CLOSED_REASONS, description: "Why it ended; only kept when status is closed" },
        pay_min: { type: "integer", minimum: 0, description: "Lowest pay, whole dollars" },
        pay_max: { type: "integer", minimum: 0, description: "Highest pay, whole dollars" },
        pay_unit: { type: "string", enum: PAY_UNITS, description: "Whether pay is per hour or per year" },
        url: { type: "string", description: "Link to the posting" },
        contacted_on: { type: "string", description: "Date first contacted (#{DATE_NOTE})" },
        follow_up_on: { type: "string", description: "Date to follow up (#{DATE_NOTE})" },
        notes: { type: "string", description: "Free-form notes" },
        external_id: { type: "string", description: "The job board's id for the posting (e.g. 42472), or any stable key. " \
                                                       "Unique: used to catch duplicates" },
        resume_version: { type: "string", description: "Which resume was sent (e.g. a file name or version label)" },
        contact_name: { type: "string", description: "The person at the company to contact, a recruiter or hiring manager" },
        application_channel: { type: "string", enum: APPLICATION_CHANNELS, description: "Where the application went: email, the company's form, a hiring platform (ats), or a referral" },
        last_verified_on: { type: "string", description: "Date the posting was last confirmed still live (#{DATE_NOTE})" }
      }.freeze
      DATE_FIELDS = %i[contacted_on follow_up_on last_verified_on].freeze

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

        # Creates one opportunity, or says why not. Returns [:created | :duplicate | :invalid | :error, value]
        # where value is the record (or the problem text for :error). Used by create and bulk create so both
        # treat duplicates the same way: a repeated external_id or posting URL is reported, never re-added.
        def create_or_report(attributes)
          attributes = clean(attributes.to_h.symbolize_keys)
          if (problem = check_dates(attributes))
            return [ :error, problem ]
          end

          editable = attributes.slice(*Opportunity::EDITABLE_ATTRIBUTES)
          existing = Opportunity.find_duplicate(external_id: editable[:external_id], url: editable[:url])
          return [ :duplicate, existing ] if existing

          opportunity = Opportunity.new(editable)
          [ opportunity.save ? :created : :invalid, opportunity ]
        rescue ActiveRecord::RecordNotUnique
          # Lost a race with another request that saved the same external_id.
          [ :duplicate, Opportunity.find_duplicate(external_id: editable[:external_id]) ]
        end

        def duplicate_summary(existing)
          "Already tracked as id #{existing.id} (#{existing.company}, #{existing.role}, status #{existing.status}" \
            "#{", archived" if existing.archived?}). Use update_opportunity to change it" \
            "#{" (archive_opportunity with archived false restores it)" if existing.archived?}."
        end

        # Optional enums arrive as "" when the model means "unset".
        def clean(attributes)
          attributes.transform_values { |value| value == "" ? nil : value }
        end
      end
    end
  end
end
