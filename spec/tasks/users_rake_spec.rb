require "rails_helper"
require "rake"

RSpec.describe "users:create" do
  before(:all) { Rails.application.load_tasks unless Rake::Task.task_defined?("users:create") }

  let(:task) { Rake::Task["users:create"] }

  around do |example|
    task.reenable
    original = ENV["PASSWORD"]
    example.run
  ensure
    ENV["PASSWORD"] = original
  end

  it "creates a user whose password works" do
    ENV["PASSWORD"] = "correct horse battery"

    expect { task.invoke("Me@Example.com ") }.to output(/Created me@example.com/).to_stdout

    expect(User.find_by(email_address: "me@example.com").authenticate("correct horse battery")).to be_truthy
  end

  it "updates the password of an existing user" do
    create(:user, email_address: "me@example.com")
    ENV["PASSWORD"] = "a brand new password"

    expect { task.invoke("me@example.com") }.to output(/Updated me@example.com/).to_stdout

    expect(User.count).to eq(1)
    expect(User.first.authenticate("a brand new password")).to be_truthy
  end

  it "refuses a short password" do
    ENV["PASSWORD"] = "short"

    expect { task.invoke("me@example.com") }.to raise_error(SystemExit).and output(/at least 12/).to_stderr
    expect(User.count).to eq(0)
  end

  it "needs an email" do
    expect { task.invoke }.to raise_error(SystemExit).and output(/Usage/).to_stderr
  end
end
