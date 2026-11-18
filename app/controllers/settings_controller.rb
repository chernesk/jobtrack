class SettingsController < ApplicationController
  def show
    render inertia: "Settings/Edit", props: { settings: Setting.current.as_props }
  end

  def update
    setting = Setting.current

    if setting.update(setting_attributes)
      redirect_to settings_path, notice: "Settings saved."
    else
      redirect_to settings_path, inertia: { errors: setting.errors.to_hash.transform_values(&:first) }
    end
  end

  # Sends a real message with the saved settings, so the setup can be checked
  # without waiting for 7am. It ignores the on/off switch: testing is the point.
  def test
    if !NtfyClient.configured?
      redirect_to settings_path, alert: "Set a topic first (here or in NTFY_TOPIC), then save."
    elsif NtfyClient.publish(title: "JobTrack test", message: "If you can read this, notifications work.", tags: "tada")
      redirect_to settings_path, notice: "Test notification sent. Check your phone."
    else
      redirect_to settings_path, alert: "The test could not be sent. Check the server address and topic; the app log has the reason."
    end
  end

  private

  def setting_attributes
    permitted = params.expect(setting: %i[
      auto_refresh_enabled auto_refresh_seconds notifications_enabled notify_when_nothing_due
      hide_names ntfy_url ntfy_topic ntfy_token clear_ntfy_token app_url
    ])

    token = permitted.delete(:ntfy_token).to_s.strip
    clear_token = ActiveModel::Type::Boolean.new.cast(permitted.delete(:clear_ntfy_token))

    # A blank token field means "leave the saved one alone"; only the checkbox removes it.
    permitted[:ntfy_token] = nil if clear_token
    permitted[:ntfy_token] = token if token.present? && !clear_token
    permitted
  end
end
