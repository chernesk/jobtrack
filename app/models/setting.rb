# The app's settings: one row, edited on the Settings page. A blank notification
# field falls back to the matching environment variable (NTFY_TOPIC and so on), so a
# setup that already uses them keeps working, and the page shows where a value comes from.
class Setting < ApplicationRecord
  REFRESH_CHOICES = [ 10, 15, 30, 60, 120 ].freeze

  # The saved token is encrypted at rest. A token that cannot be decrypted (the
  # signing secret changed) reads as "none saved" instead of breaking the page.
  encrypts :ntfy_token

  before_validation :tidy_text

  validates :auto_refresh_seconds, inclusion: { in: REFRESH_CHOICES, message: "must be one of #{REFRESH_CHOICES.join(', ')}" }
  validates :ntfy_topic, format: { with: /\A[A-Za-z0-9_-]{1,64}\z/, message: "can only use letters, numbers, - and _ (up to 64)" }, allow_nil: true
  validates :ntfy_url, :app_url, format: { with: %r{\Ahttps?://[^\s/]+\S*\z}i, message: "must start with http:// or https://" }, allow_nil: true

  # There is only ever one row. Created on first use with the defaults.
  def self.current
    first || create!
  end

  def effective_ntfy_url = ntfy_url.presence || ENV["NTFY_URL"].presence
  def effective_ntfy_topic = ntfy_topic.presence || ENV["NTFY_TOPIC"].presence
  def effective_ntfy_token = saved_token.presence || ENV["NTFY_TOKEN"].presence
  def effective_app_url = app_url.presence || ENV["APP_URL"].presence
  def effective_hide_names? = hide_names? || ENV["NTFY_HIDE_NAMES"].present?

  # What the page needs. The token itself never leaves the server: only whether one is saved.
  def as_props
    {
      auto_refresh_enabled: auto_refresh_enabled,
      auto_refresh_seconds: auto_refresh_seconds,
      notifications_enabled: notifications_enabled,
      notify_when_nothing_due: notify_when_nothing_due,
      hide_names: hide_names,
      ntfy_url: ntfy_url,
      ntfy_topic: ntfy_topic,
      app_url: app_url,
      ntfy_token_saved: saved_token.present?,
      from_environment: {
        ntfy_url: ENV["NTFY_URL"].present?,
        ntfy_topic: ENV["NTFY_TOPIC"].present?,
        ntfy_token: ENV["NTFY_TOKEN"].present?,
        app_url: ENV["APP_URL"].present?,
        hide_names: ENV["NTFY_HIDE_NAMES"].present?
      }
    }
  end

  # Shared with every page so `useAutoRefresh` knows whether and how often to poll.
  def refresh_props
    { enabled: auto_refresh_enabled, seconds: auto_refresh_seconds }
  end

  private

  def saved_token
    ntfy_token
  rescue ActiveRecord::Encryption::Errors::Decryption
    nil
  end

  def tidy_text
    %i[ntfy_url ntfy_topic app_url].each do |field|
      self[field] = self[field].to_s.strip.presence
    end
    self.ntfy_url = ntfy_url.chomp("/") if ntfy_url
  end
end
