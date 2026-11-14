# Fictional demo account (development only; never use real credentials).
User.find_or_create_by!(email_address: "demo@example.com") do |user|
  user.password = "password"
end
