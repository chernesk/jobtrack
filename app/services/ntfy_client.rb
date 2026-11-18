require "net/http"

# Sends a push notification through ntfy (https://ntfy.sh), which the ntfy phone app
# receives. Configured by environment variables, so nothing about where messages go
# is in the repo:
#
#   NTFY_TOPIC   required. Without it, notifications are off and `publish` does nothing.
#   NTFY_URL     the ntfy server. Defaults to https://ntfy.sh; set it for a self-hosted one.
#   NTFY_TOKEN   optional access token, for a topic that needs one.
#
# A notification is a convenience, never a reason for work to fail: `publish` logs and
# returns false on any network error or error response rather than raising.
class NtfyClient
  DEFAULT_URL = "https://ntfy.sh".freeze
  TIMEOUT_SECONDS = 5

  def self.configured?
    ENV["NTFY_TOPIC"].present?
  end

  # `click` is a URL the phone opens when the notification is tapped.
  # Header values must be plain ASCII, so title, tags and priority stay simple;
  # anything free-form (company names) belongs in the body, which is UTF-8.
  def self.publish(title:, message:, click: nil, priority: nil, tags: nil)
    return false unless configured?

    uri = URI.join(ENV.fetch("NTFY_URL", DEFAULT_URL).to_s.chomp("/") + "/", ENV.fetch("NTFY_TOPIC"))
    request = Net::HTTP::Post.new(uri)
    request.body = message
    request["Title"] = title
    request["Click"] = click if click.present?
    request["Priority"] = priority.to_s if priority
    request["Tags"] = tags if tags.present?
    request["Authorization"] = "Bearer #{ENV['NTFY_TOKEN']}" if ENV["NTFY_TOKEN"].present?

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                               open_timeout: TIMEOUT_SECONDS, read_timeout: TIMEOUT_SECONDS) do |http|
      http.request(request)
    end

    return true if response.is_a?(Net::HTTPSuccess)

    Rails.logger.warn("NtfyClient: #{uri.host} answered #{response.code}")
    false
  rescue StandardError => error
    Rails.logger.warn("NtfyClient: could not send (#{error.class}: #{error.message})")
    false
  end
end
