namespace :users do
  desc "Create (or update the password of) a user: bin/rails 'users:create[you@example.com]' (prompts for the password)"
  task :create, [ :email ] => :environment do |_task, args|
    email = args[:email].to_s.strip
    abort "Usage: bin/rails 'users:create[you@example.com]'" if email.empty?

    require "io/console"
    password = ENV["PASSWORD"].presence || $stdin.getpass("Password (input hidden): ")
    abort "Password must be at least 12 characters." if password.to_s.length < 12

    user = User.find_or_initialize_by(email_address: email)
    user.password = password
    user.save!
    puts "#{user.previously_new_record? ? "Created" : "Updated"} #{user.email_address}"
  end
end
