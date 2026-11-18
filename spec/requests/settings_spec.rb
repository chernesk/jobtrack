require "rails_helper"

RSpec.describe "Settings", type: :request do
  def sign_in
    user = create(:user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  def props
    get settings_path, headers: { "X-Inertia" => "true" }
    response.parsed_body["props"]
  end

  around do |example|
    keys = %w[NTFY_TOPIC NTFY_URL NTFY_TOKEN APP_URL NTFY_HIDE_NAMES]
    saved = ENV.to_h.slice(*keys)
    keys.each { |key| ENV.delete(key) }
    example.run
    keys.each { |key| ENV.delete(key) }
    saved.each { |key, value| ENV[key] = value }
  end

  it "requires sign-in" do
    get settings_path
    expect(response).to redirect_to(new_session_path)

    patch settings_path, params: { setting: { hide_names: true } }
    expect(response).to redirect_to(new_session_path)

    post test_settings_path
    expect(response).to redirect_to(new_session_path)
  end

  context "when signed in" do
    before { sign_in }

    it "renders the page with the current settings and no token value" do
      Setting.current.update!(ntfy_topic: "my-topic", ntfy_token: "tk_secret")

      get settings_path, headers: { "X-Inertia" => "true" }

      expect(response.parsed_body["component"]).to eq("Settings/Edit")
      expect(response.parsed_body["props"]["settings"]).to include("ntfy_topic" => "my-topic", "ntfy_token_saved" => true)
      expect(response.body).not_to include("tk_secret")
    end

    it "shares the refresh settings with every page" do
      Setting.current.update!(auto_refresh_enabled: false, auto_refresh_seconds: 60)

      get root_path, headers: { "X-Inertia" => "true" }

      expect(response.parsed_body["props"]["auto_refresh"]).to eq("enabled" => false, "seconds" => 60)
    end

    describe "PATCH /settings" do
      it "saves the settings and redirects back with a notice" do
        patch settings_path, params: { setting: {
          auto_refresh_enabled: false, auto_refresh_seconds: 30, notifications_enabled: false,
          notify_when_nothing_due: false, hide_names: true, ntfy_topic: "my-topic",
          ntfy_url: "http://nas.local:8080", app_url: "http://nas.local:3200"
        } }

        expect(response).to redirect_to(settings_path)
        expect(flash[:notice]).to eq("Settings saved.")
        expect(Setting.current).to have_attributes(
          auto_refresh_enabled: false, auto_refresh_seconds: 30, notifications_enabled: false,
          notify_when_nothing_due: false, hide_names: true, ntfy_topic: "my-topic",
          ntfy_url: "http://nas.local:8080", app_url: "http://nas.local:3200"
        )
      end

      it "returns the first error per field and saves nothing when something is invalid" do
        patch settings_path, params: { setting: { ntfy_topic: "bad topic", auto_refresh_seconds: 30 } }

        expect(response).to redirect_to(settings_path)
        follow_redirect!
        expect(response.body).to include("can only use letters")
        expect(Setting.current).to have_attributes(ntfy_topic: nil, auto_refresh_seconds: 15)
      end

      it "saves a new token, keeps it when the field is left blank, and removes it only when asked" do
        patch settings_path, params: { setting: { ntfy_token: "tk_first" } }
        expect(Setting.current.effective_ntfy_token).to eq("tk_first")

        patch settings_path, params: { setting: { ntfy_token: "", hide_names: true } }
        expect(Setting.current.effective_ntfy_token).to eq("tk_first")

        patch settings_path, params: { setting: { ntfy_token: "", clear_ntfy_token: "1" } }
        expect(Setting.current.effective_ntfy_token).to be_nil
      end

      it "ignores attributes it was not meant to accept" do
        expect { patch settings_path, params: { setting: { id: 99, created_at: "2000-01-01" } } }
          .not_to(change { Setting.current.created_at })
      end
    end

    describe "POST /settings/test" do
      it "asks for a topic when there is none, and sends nothing" do
        allow(NtfyClient).to receive(:publish)

        post test_settings_path

        expect(flash[:alert]).to include("Set a topic first")
        expect(NtfyClient).not_to have_received(:publish)
      end

      it "sends a test message with the saved settings, even when notifications are switched off" do
        Setting.current.update!(ntfy_topic: "my-topic", notifications_enabled: false)
        allow(NtfyClient).to receive(:publish).and_return(true)

        post test_settings_path

        expect(flash[:notice]).to include("Test notification sent")
        expect(NtfyClient).to have_received(:publish).with(hash_including(title: "JobTrack test"))
      end

      it "says so when the send fails" do
        Setting.current.update!(ntfy_topic: "my-topic")
        allow(NtfyClient).to receive(:publish).and_return(false)

        post test_settings_path

        expect(flash[:alert]).to include("could not be sent")
      end
    end
  end
end
