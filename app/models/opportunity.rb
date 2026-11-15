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
  # `scopes: false`: Rails would also generate negative scopes named `not_<status>`, and
  # `not_contacted` collides with our own "not_contacted" status. Filtering uses `with_status`.
  enum :status, STATUSES.index_with(&:itself), default: "not_contacted", validate: true, scopes: false
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
    # Arel's `matches` is a case-insensitive LIKE on every database (ILIKE on Postgres,
    # LIKE ... ESCAPE on SQLite), so the wildcard escaping below works on either.
    pattern = "%#{sanitize_sql_like(term)}%"
    where(arel_table[:company].matches(pattern, "\\").or(arel_table[:role].matches(pattern, "\\"))) if term.present?
  }
  # Soonest follow-up first by default; records without a follow-up date sort last either way.
  scope :by_follow_up, lambda { |direction = :asc|
    column = arel_table[:follow_up_on]
    order(direction.to_s == "desc" ? column.desc.nulls_last : column.asc.nulls_last, :company, :id)
  }

  # Open opportunities whose follow-up date is `on` or earlier (today or overdue),
  # most overdue first. The dashboard lists these.
  scope :follow_up_due, lambda { |on = Date.current|
    where(status: OPEN_STATUSES).where(follow_up_on: ..on).order(:follow_up_on, :company, :id)
  }

  # `due` is stored so the dashboard can read it with one indexed query. It changes
  # with time as well as with edits, so two things keep it right: this callback when a
  # record is saved, and FollowUpReminderJob each morning when a date passes untouched.
  before_save :sync_due

  # Same rule as `follow_up_due`, for a single record.
  def due_on?(date = Date.current)
    OPEN_STATUSES.include?(status) && follow_up_on.present? && follow_up_on <= date
  end

  # Flagged by the daily job (or on save). Most overdue first.
  scope :flagged_due, -> { where(due: true).order(:follow_up_on, :company, :id) }

  # New cards land at the bottom of their status column.
  before_create :assign_position, if: -> { position.zero? }

  # Moves this card to `new_status` at `index` (0-based) among that column's other
  # cards, then renumbers positions to 1..n so ordering never has gaps or ties.
  # Returns false (with errors set) if the status is invalid; nothing changes then.
  def move_to(new_status, index)
    unless self.class.statuses.key?(new_status.to_s)
      errors.add(:status, "is not a valid status")
      return false
    end

    moved = false
    transaction do
      previous_status = status
      column = self.class.where(status: new_status).where.not(id: id).order(:position, :id).lock.to_a
      column.insert(index.to_i.clamp(0, column.size), self)

      self.status = new_status
      self.position = column.index(self) + 1
      moved = save
      raise ActiveRecord::Rollback unless moved

      column.each.with_index(1) { |card, position| card.update_columns(position: position) unless card == self || card.position == position }
      renumber(previous_status) unless previous_status == new_status
    end
    moved
  end

  def as_props
    as_json(only: PROP_ATTRIBUTES)
  end

  private

  def sync_due
    self.due = due_on?
  end

  def renumber(column_status)
    self.class.where(status: column_status).order(:position, :id).each.with_index(1) do |card, position|
      card.update_columns(position: position) unless card.position == position
    end
  end

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
