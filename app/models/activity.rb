class Activity < ApplicationRecord
  belongs_to :opportunity

  enum :kind, { email: "email", call: "call", interview: "interview", note: "note" }, validate: true

  validates :occurred_on, :body, presence: true

  # Attributes sent to React pages (typed as `Activity` in app/frontend/types.ts).
  PROP_ATTRIBUTES = %w[id kind occurred_on body].freeze

  def as_props
    as_json(only: PROP_ATTRIBUTES)
  end
end
