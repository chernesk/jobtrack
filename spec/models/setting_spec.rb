require "rails_helper"

RSpec.describe Setting do
  around do |example|
    keys = %w[NTFY_TOPIC NTFY_URL NTFY_TOKEN APP_URL NTFY_HIDE_NAMES]
    saved = ENV.to_h.slice(*keys)
    keys.each { |key| ENV.delete(key) }
    example.run
    keys.each { |key| ENV.delete(key) }
    saved.each { |key, value| ENV[key] = value }
  end

  it "creates one row with the defaults the app had before settings existed" do
    setting = described_class.current

    expect(described_class.current).to eq(setting)
    expect(described_class.count).to eq(1)
    expect(setting).to have_attributes(
      auto_refresh_enabled: true, auto_refresh_seconds: 15, notifications_enabled: true,
      notify_when_nothing_due: true, hide_names: false, ntfy_topic: nil
    )
  end

  describe "validation" do
    it "only accepts the refresh intervals the page offers" do
      expect(described_class.new(auto_refresh_seconds: 30)).to be_valid
      expect(described_class.new(auto_refresh_seconds: 1)).not_to be_valid
    end

    it "limits a topic to the characters ntfy allows" do
      expect(described_class.new(ntfy_topic: "my-topic_42")).to be_valid
      expect(described_class.new(ntfy_topic: "has space")).not_to be_valid
      expect(described_class.new(ntfy_topic: "a/b")).not_to be_valid
    end

    it "requires http or https for the server and app addresses" do
      expect(described_class.new(ntfy_url: "http://nas.local:8080", app_url: "https://jobs.example")).to be_valid
      expect(described_class.new(ntfy_url: "nas.local")).not_to be_valid
      expect(described_class.new(app_url: "javascript:alert(1)")).not_to be_valid
    end

    it "treats blank text as not set and tidies the server address" do
      setting = described_class.create!(ntfy_topic: "  ", ntfy_url: " http://nas.local:8080/ ", app_url: "")

      expect(setting).to have_attributes(ntfy_topic: nil, ntfy_url: "http://nas.local:8080", app_url: nil)
    end
  end

  describe "environment fallback" do
    it "uses the environment variables when the setting is blank" do
      ENV["NTFY_TOPIC"] = "env-topic"
      ENV["NTFY_URL"] = "http://env.local"
      ENV["APP_URL"] = "http://app.local"
      ENV["NTFY_HIDE_NAMES"] = "1"

      setting = described_class.new

      expect(setting).to have_attributes(effective_ntfy_topic: "env-topic", effective_ntfy_url: "http://env.local",
                                         effective_app_url: "http://app.local", effective_hide_names?: true)
    end

    it "prefers a saved value over the environment" do
      ENV["NTFY_TOPIC"] = "env-topic"

      expect(described_class.new(ntfy_topic: "saved-topic").effective_ntfy_topic).to eq("saved-topic")
    end

    it "reports which values come from the environment, without revealing them" do
      ENV["NTFY_TOPIC"] = "env-topic"

      expect(described_class.new.as_props[:from_environment]).to include(ntfy_topic: true, ntfy_token: false)
      expect(described_class.new.as_props.to_s).not_to include("env-topic")
    end
  end

  describe "the saved token" do
    it "is encrypted in the database and never sent to the page" do
      setting = described_class.create!(ntfy_token: "tk_supersecret")

      stored = described_class.connection.select_value("SELECT ntfy_token FROM settings WHERE id = #{setting.id}")
      expect(stored).not_to include("tk_supersecret")
      expect(setting.reload.effective_ntfy_token).to eq("tk_supersecret")
      expect(setting.as_props).to include(ntfy_token_saved: true)
      expect(setting.as_props.to_s).not_to include("tk_supersecret")
    end

    it "reads as not saved, instead of raising, when it can no longer be decrypted" do
      setting = described_class.create!
      described_class.connection.execute("UPDATE settings SET ntfy_token = 'not-valid-ciphertext' WHERE id = #{setting.id}")

      expect(setting.reload.as_props).to include(ntfy_token_saved: false)
      expect(setting.effective_ntfy_token).to be_nil
    end

    it "falls back to NTFY_TOKEN when none is saved" do
      ENV["NTFY_TOKEN"] = "tk_env"

      expect(described_class.new.effective_ntfy_token).to eq("tk_env")
    end
  end
end
