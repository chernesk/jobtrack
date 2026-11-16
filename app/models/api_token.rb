# A bearer token for the JSON API. The plaintext is shown once, when it is issued;
# only its digest is stored. Tokens are long random strings, so a plain SHA-256 is
# enough (no need for a slow password hash) and lets us look one up by an indexed column.
class ApiToken < ApplicationRecord
  belongs_to :user

  validates :name, presence: true

  # Returns [record, plaintext]. The plaintext cannot be recovered later.
  def self.issue(user:, name:)
    plaintext = SecureRandom.urlsafe_base64(32)
    [ create!(user: user, name: name, token_digest: digest(plaintext)), plaintext ]
  end

  # The token record for a presented plaintext token, or nil.
  def self.authenticate(plaintext)
    return if plaintext.blank?

    find_by(token_digest: digest(plaintext))
  end

  def self.digest(plaintext)
    Digest::SHA256.hexdigest(plaintext)
  end

  # Throttled to one write per hour so a busy client doesn't write on every request.
  def touch_last_used
    update_column(:last_used_at, Time.current) if last_used_at.nil? || last_used_at < 1.hour.ago
  end
end
