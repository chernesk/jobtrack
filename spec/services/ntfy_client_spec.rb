require "rails_helper"

RSpec.describe NtfyClient do
  let(:sent) { [] }
  let(:response) { Net::HTTPOK.new("1.1", "200", "OK") }

  # No real network: capture the request instead of sending it.
  before do
    allow(Net::HTTP).to receive(:start) do |host, port, **options, &block|
      http = instance_double(Net::HTTP)
      allow(http).to receive(:request) do |request|
        sent << { host: host, port: port, ssl: options[:use_ssl], request: request }
        response
      end
      block.call(http)
    end
  end

  around do |example|
    keys = %w[NTFY_TOPIC NTFY_URL NTFY_TOKEN]
    saved = ENV.to_h.slice(*keys)
    keys.each { |key| ENV.delete(key) }
    example.run
    keys.each { |key| ENV.delete(key) }
    saved.each { |key, value| ENV[key] = value }
  end

  it "is configured by a topic saved in settings alone" do
    Setting.current.update!(ntfy_topic: "saved-topic")

    expect(described_class.configured?).to be(true)
  end

  it "does nothing when no topic is configured" do
    expect(described_class.configured?).to be(false)
    expect(described_class.publish(title: "Hi", message: "There")).to be(false)
    expect(sent).to be_empty
  end

  context "with a topic" do
    before { ENV["NTFY_TOPIC"] = "my-private-topic" }

    it "posts the message to ntfy.sh by default, with a title" do
      expect(described_class.publish(title: "3 follow-ups due", message: "Acme, Engineer")).to be(true)

      call = sent.first
      expect([ call[:host], call[:port], call[:ssl] ]).to eq([ "ntfy.sh", 443, true ])
      expect(call[:request].path).to eq("/my-private-topic")
      expect(call[:request].body).to eq("Acme, Engineer")
      expect(call[:request]["Title"]).to eq("3 follow-ups due")
    end

    it "sends priority, tags and a click URL when given, and omits them otherwise" do
      described_class.publish(title: "T", message: "M", click: "http://nas:3200", priority: 4, tags: "bell")
      described_class.publish(title: "T", message: "M")

      with, without = sent.map { |call| call[:request] }
      expect([ with["Click"], with["Priority"], with["Tags"] ]).to eq([ "http://nas:3200", "4", "bell" ])
      expect([ without["Click"], without["Priority"], without["Tags"] ]).to all(be_nil)
    end

    it "uses a self-hosted server and a token when configured" do
      ENV["NTFY_URL"] = "http://nas.local:8080/"
      ENV["NTFY_TOKEN"] = "tk_secret"

      described_class.publish(title: "T", message: "M")

      call = sent.first
      expect([ call[:host], call[:port], call[:ssl] ]).to eq([ "nas.local", 8080, false ])
      expect(call[:request].path).to eq("/my-private-topic")
      expect(call[:request]["Authorization"]).to eq("Bearer tk_secret")
    end

    it "uses the topic, server and token saved in settings, ahead of the environment" do
      ENV["NTFY_URL"] = "http://env.local"
      Setting.current.update!(ntfy_topic: "saved-topic", ntfy_url: "http://saved.local:9000", ntfy_token: "tk_saved")

      described_class.publish(title: "T", message: "M")

      call = sent.first
      expect([ call[:host], call[:port] ]).to eq([ "saved.local", 9000 ])
      expect(call[:request].path).to eq("/saved-topic")
      expect(call[:request]["Authorization"]).to eq("Bearer tk_saved")
    end

    it "returns false instead of raising on an error response" do
      allow(response).to receive(:code).and_return("503")
      failing = Net::HTTPServiceUnavailable.new("1.1", "503", "Unavailable")

      allow(Net::HTTP).to receive(:start).and_return(failing)

      expect(described_class.publish(title: "T", message: "M")).to be(false)
    end

    it "returns false instead of raising when the network fails" do
      allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNREFUSED)

      expect(described_class.publish(title: "T", message: "M")).to be(false)
    end
  end
end
