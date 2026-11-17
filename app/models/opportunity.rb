class Opportunity < ApplicationRecord
  # Statuses in board order (left to right).
  # `recommended` is a match worth applying to but not yet acted on; `applied` is submitted, no reply.
  STATUSES = %w[recommended not_contacted contacted applied talking interviewing offer closed].freeze
  # Statuses that still need attention (used by the follow-up reminder).
  OPEN_STATUSES = (STATUSES - %w[closed]).freeze

  # Statuses where the posting itself may still disappear or fill. Once someone is talking to you the
  # posting no longer matters, so these are the ones worth re-checking.
  POSTING_STATUSES = %w[recommended not_contacted contacted applied].freeze

  # Attributes sent to React pages (typed as `Opportunity` in app/frontend/types.ts).
  PROP_ATTRIBUTES = %w[
    id company role kind source status closed_reason pay_min pay_max pay_unit url
    contacted_on follow_up_on notes position archived_at external_id last_verified_on
  ].freeze

  # Fields a user may set (web form and JSON API). `position` is owned by the board.
  EDITABLE_ATTRIBUTES = %i[
    company role kind source status closed_reason pay_min pay_max pay_unit url contacted_on follow_up_on notes
    external_id last_verified_on
  ].freeze
  # Optional enums: an empty value means "not chosen".
  NULLABLE_ENUMS = %w[kind source pay_unit closed_reason].freeze

  has_many :activities, dependent: :destroy

  enum :kind, { full_time: "full_time", contract_w2: "contract_w2", contract_c2c: "contract_c2c" }, validate: { allow_nil: true }
  enum :source, { network: "network", recruiter: "recruiter", agency: "agency", job_board: "job_board", direct: "direct" }, validate: { allow_nil: true }
  # `scopes: false`: Rails would also generate negative scopes named `not_<status>`, and
  # `not_contacted` collides with our own "not_contacted" status. Filtering uses `with_status`.
  enum :status, STATUSES.index_with(&:itself), default: "not_contacted", validate: true, scopes: false
  # Why a closed opportunity ended. Only kept while the status is closed (see `clear_closed_reason`).
  enum :closed_reason, {
    rejected: "rejected", withdrew: "withdrew", posting_closed: "posting_closed",
    mistake: "mistake", other: "other"
  }, prefix: :closed_because, validate: { allow_nil: true }
  enum :pay_unit, { hourly: "hourly", yearly: "yearly" }, validate: { allow_nil: true }

  # The job board's own id (or any stable key). Unique when present, so the same posting is never
  # tracked twice; many records may have none.
  before_validation { self.external_id = external_id.to_s.strip.presence }
  validates :external_id, uniqueness: { message: "is already tracked" }, allow_nil: true

  validate :url_not_already_tracked, if: -> { url_changed? && url.present? }

  validates :company, :role, presence: true
  validates :pay_min, :pay_max, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validate :pay_max_not_below_pay_min
  validate :follow_up_not_before_contacted

  # Archived records are hidden everywhere (board, list, counts, reminders) but kept, so a
  # mistaken entry can be set aside without destroying data. `archived` is the opposite view.
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  # Index filters. Each returns `all` for a blank or unknown value, so a
  # mistyped query string never raises or hides every record.
  scope :with_status, ->(value) { where(status: value) if statuses.key?(value.to_s) }
  scope :with_kind, ->(value) { where(kind: value) if kinds.key?(value.to_s) }
  scope :search, lambda { |query|
    term = query.to_s.strip
    # Arel's `matches` is a case-insensitive LIKE on every database (ILIKE on Postgres,
    # LIKE ... ESCAPE on SQLite), so the wildcard escaping below works on either.
    pattern = "%#{sanitize_sql_like(term)}%"
    if term.present?
      where(arel_table[:company].matches(pattern, "\\").or(arel_table[:role].matches(pattern, "\\"))
        .or(arel_table[:external_id].matches(pattern, "\\")))
    end
  }
  # Soonest follow-up first by default; records without a follow-up date sort last either way.
  scope :by_follow_up, lambda { |direction = :asc|
    column = arel_table[:follow_up_on]
    order(direction.to_s == "desc" ? column.desc.nulls_last : column.asc.nulls_last, :company, :id)
  }

  # Postings not checked since `before` (or never), oldest first. Archived and late-stage records are left out.
  scope :stale_postings, lambda { |before|
    column = arel_table[:last_verified_on]
    active.where(status: POSTING_STATUSES).where(column.eq(nil).or(column.lt(before)))
      .order(column.asc.nulls_first, :company, :id)
  }

  # Open opportunities whose follow-up date is `on` or earlier (today or overdue),
  # most overdue first. The dashboard lists these.
  scope :follow_up_due, lambda { |on = Date.current|
    active.where(status: OPEN_STATUSES).where(follow_up_on: ..on).order(:follow_up_on, :company, :id)
  }

  # `due` is stored so the dashboard can read it with one indexed query. It changes
  # with time as well as with edits, so two things keep it right: this callback when a
  # record is saved, and FollowUpReminderJob each morning when a date passes untouched.
  before_save :sync_due
  before_save :clear_closed_reason

  # Same rule as `follow_up_due`, for a single record.
  def due_on?(date = Date.current)
    !archived? && OPEN_STATUSES.include?(status) && follow_up_on.present? && follow_up_on <= date
  end

  # Flagged by the daily job (or on save). Most overdue first.
  scope :flagged_due, -> { active.where(due: true).order(:follow_up_on, :company, :id) }

  # New cards land at the bottom of their status column.
  before_create :assign_position, if: -> { position.zero? }

  # The existing record that `external_id` or `url` points at, if any (archived ones included, so an
  # archived entry is not re-added by accident). A URL matches ignoring case in the host, a trailing
  # slash and any #fragment. Compared in Ruby: this is a personal tracker, so the table is small.
  def self.find_duplicate(external_id: nil, url: nil)
    key = external_id.to_s.strip
    return find_by(external_id: key) if key.present? && exists?(external_id: key)

    target = normalize_url(url)
    return if target.blank?

    where.not(url: [ nil, "" ]).find { |opportunity| normalize_url(opportunity.url) == target }
  end

  def self.normalize_url(value)
    uri = URI.parse(value.to_s.strip)
    return value.to_s.strip.presence unless uri.host

    "#{uri.scheme}://#{uri.host.downcase}#{uri.port == uri.default_port ? "" : ":#{uri.port}"}#{uri.path.chomp("/")}#{"?#{uri.query}" if uri.query}"
  rescue URI::InvalidURIError
    value.to_s.strip.presence
  end

  def archived?
    archived_at.present?
  end

  # Takes the card off its column (closing the gap) without deleting anything.
  def archive!
    return true if archived?

    transaction do
      update!(archived_at: Time.current)
      renumber(status)
    end
  end

  # Brings it back at the bottom of its column.
  def unarchive!
    return true unless archived?

    update!(archived_at: nil, position: next_position)
  end

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
      column = self.class.active.where(status: new_status).where.not(id: id).order(:position, :id).lock.to_a
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

  # A reason only makes sense while closed; reopening an opportunity forgets it.
  def clear_closed_reason
    self.closed_reason = nil unless status == "closed"
  end

  def renumber(column_status)
    self.class.active.where(status: column_status).order(:position, :id).each.with_index(1) do |card, position|
      card.update_columns(position: position) unless card.position == position
    end
  end

  def url_not_already_tracked
    existing = self.class.find_duplicate(url: url)
    errors.add(:url, "is already tracked (#{existing.company}, #{existing.role})") if existing && existing != self
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
    self.position = next_position
  end

  def next_position
    (self.class.active.where(status: status).maximum(:position) || 0) + 1
  end
end
