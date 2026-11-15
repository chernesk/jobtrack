class Opportunity < ApplicationRecord
  # Statuses in board order (left to right).
  STATUSES = %w[not_contacted contacted talking interviewing offer closed].freeze
  # Statuses that still need attention (used by the follow-up reminder).
  OPEN_STATUSES = (STATUSES - %w[closed]).freeze

  # Attributes sent to React pages (typed as `Opportunity` in app/frontend/types.ts).
  PROP_ATTRIBUTES = %w[
    id company role kind source status pay_min pay_max pay_unit url
    contacted_on follow_up_on notes position
  ].freeze

  has_many :activities, dependent: :destroy

  enum :kind, { full_time: "full_time", contract_w2: "contract_w2", contract_c2c: "contract_c2c" }, validate: { allow_nil: true }
  enum :source, { network: "network", recruiter: "recruiter", agency: "agency", job_board: "job_board", direct: "direct" }, validate: { allow_nil: true }
  enum :status, STATUSES.index_with(&:itself), default: "not_contacted", validate: true
  enum :pay_unit, { hourly: "hourly", yearly: "yearly" }, validate: { allow_nil: true }

  validates :company, :role, presence: true
  validates :pay_min, :pay_max, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validate :pay_max_not_below_pay_min
  validate :follow_up_not_before_contacted

  # Index filters. Each returns `all` for a blank or unknown value, so a
  # mistyped query string never raises or hides every record.
  scope :with_status, ->(value) { where(status: value) if statuses.key?(value.to_s) }
  scope :with_kind, ->(value) { where(kind: value) if kinds.key?(value.to_s) }
  scope :search, lambda { |query|
    term = query.to_s.strip
    where("opportunities.company ILIKE :term OR opportunities.role ILIKE :term", term: "%#{sanitize_sql_like(term)}%") if term.present?
  }
  # Soonest follow-up first by default; records without a follow-up date sort last either way.
  scope :by_follow_up, lambda { |direction = :asc|
    column = arel_table[:follow_up_on]
    order(direction.to_s == "desc" ? column.desc.nulls_last : column.asc.nulls_last, :company, :id)
  }

  # New cards land at the bottom of their status column.
  before_create :assign_position, if: -> { position.zero? }

  def as_props
    as_json(only: PROP_ATTRIBUTES)
  end

  private

  def pay_max_not_below_pay_min
    return if pay_min.nil? || pay_max.nil?

    errors.add(:pay_max, "must be greater than or equal to minimum pay") if pay_max < pay_min
  end

  def follow_up_not_before_contacted
    return if contacted_on.nil? || follow_up_on.nil?

    errors.add(:follow_up_on, "can't be before the contacted date") if follow_up_on < contacted_on
  end

  def assign_position
    self.position = (self.class.where(status: status).maximum(:position) || 0) + 1
  end
end
