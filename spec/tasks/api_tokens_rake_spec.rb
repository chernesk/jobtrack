require "rails_helper"
require "rake"

RSpec.describe "api_tokens:create" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("api_tokens:create") }

  let(:task) { Rake::Task["api_tokens:create"] }

  before { task.reenable }

  it "issues a token that authenticates, printing it once" do
    user = create(:user, email_address: "me@example.com")

    output = capture_stdout { task.invoke("Me@Example.com", "laptop") }
    plaintext = output.lines.last.strip

    expect(ApiToken.authenticate(plaintext)).to have_attributes(user: user, name: "laptop")
  end

  it "aborts for an unknown email" do
    expect { task.invoke("nobody@example.com") }.to raise_error(SystemExit).and output(/No user/).to_stderr
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
