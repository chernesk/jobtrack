class Activity < ApplicationRecord
  belongs_to :opportunity

  enum :kind, { email: "email", call: "call", interview: "interview", note: "note" }, validate: true

  validates :occurred_on, :body, presence: true

  # Attributes sent to React pages (typed as `Activity` in app/frontend/types.ts).
  PROP_ATTRIBUTES = %w[id kind occurred_on body].freeze

  scope :recent, ->(limit = 8) { includes(:opportunity).order(occurred_on: :desc, id: :desc).limit(limit) }

  # Same as `as_props`, plus which opportunity it belongs to (for the dashboard feed).
  def as_feed_props
    as_props.merge("opportunity" => { "id" => opportunity_id, "company" => opportunity.company })
  end

  def as_props
    as_json(only: PROP_ATTRIBUTES)
  end
end
