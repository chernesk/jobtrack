# Fictional demo data only. Never add real people, companies or personal notes.
# Safe to run repeatedly: each part is skipped once it has been created.

# A known demo login must never exist on a deployed server, so this file does nothing
# in production. (`db:prepare` runs it when it creates a fresh database, which is why
# it skips quietly instead of failing.) Create the real user with `bin/rails users:create`.
if Rails.env.production?
  puts "Skipping demo seed data in production."
  return
end

User.find_or_create_by!(email_address: "demo@example.com") do |user|
  user.password = "password"
end

return if Opportunity.exists?

today = Date.current

# [company, role, kind, source, status, pay, contacted (days ago), follow-up (days from today), notes, activities, closed reason]
# pay: [min, max, unit] or nil. activities: [kind, days_ago, body]
opportunities = [
  [ "Acme Logistics", "Senior Rails Engineer", "full_time", "job_board", "recommended", [ 165_000, 195_000, "yearly" ], nil, nil,
    "Found on a job board. Warehouse routing product.",
    [ [ "note", 1, "Bookmarked the posting; want to tailor the resume first." ] ] ],
  [ "Northwind Health", "Staff Software Engineer", "full_time", "network", "recommended", [ 185_000, 220_000, "yearly" ], nil, nil,
    "A former teammate offered an intro.",
    [ [ "note", 2, "Asked for an intro; waiting on a reply." ] ] ],
  [ "Contoso Freight", "Rails Contractor", "contract_c2c", "recruiter", "not_contacted", [ 95, 115, "hourly" ], nil, nil,
    "Six-month contract, remote.",
    [ [ "email", 1, "Recruiter sent the job description." ] ] ],
  [ "Globex Payments", "Backend Engineer", "full_time", "direct", "applied", [ 160_000, 190_000, "yearly" ], 6, -1,
    "Applied directly through the careers page.",
    [ [ "email", 6, "Sent application and a short cover note." ],
      [ "note", 3, "No reply yet; follow up this week." ] ] ],
  [ "Initech Cloud", "Full-Stack Engineer", "full_time", "agency", "contacted", [ 150_000, 175_000, "yearly" ], 4, 3,
    "Agency submitted my profile.",
    [ [ "email", 4, "Agency confirmed the submission." ] ] ],
  [ "Hooli Maps", "Senior Engineer, Platform", "full_time", "recruiter", "contacted", [ 175_000, 205_000, "yearly" ], 9, 0,
    "Recruiter reached out first.",
    [ [ "email", 9, "Replied with availability and salary range." ],
      [ "call", 7, "Short intro call with the recruiter." ],
      [ "email", 5, "Sent updated resume." ] ] ],
  [ "Umbrella Analytics", "Rails Engineer", "contract_w2", "agency", "talking", [ 85, 100, "hourly" ], 14, 2,
    "W2 contract through an agency.",
    [ [ "email", 14, "Agency shared the role details." ],
      [ "call", 10, "Discussed scope and rate." ],
      [ "email", 2, "Asked about contract length and extension terms." ] ] ],
  [ "Stark Robotics", "Senior Software Engineer", "full_time", "network", "talking", [ 170_000, 200_000, "yearly" ], 12, 4,
    "Warm intro from a former colleague.",
    [ [ "email", 12, "Intro email from my contact." ],
      [ "call", 8, "Chat with the engineering manager about the team." ] ] ],
  [ "Wayne Textiles", "Backend Engineer", "full_time", "job_board", "talking", [ 140_000, 165_000, "yearly" ], 11, -2,
    "Hiring manager seemed interested.",
    [ [ "email", 11, "Applied and got a quick reply from the manager." ],
      [ "call", 9, "Phone screen scheduled and completed." ],
      [ "note", 4, "Waiting on feedback; follow up if quiet." ] ] ],
  [ "Vandelay Industries", "Principal Engineer", "full_time", "recruiter", "interviewing", [ 200_000, 240_000, "yearly" ], 25, 5,
    "Final loop is next week.",
    [ [ "email", 25, "Recruiter introduced the role." ],
      [ "call", 20, "Recruiter screen." ],
      [ "interview", 12, "Technical interview: pairing on a small Rails feature." ],
      [ "interview", 3, "System design interview with two engineers." ] ] ],
  [ "Pied Piper", "Senior Rails Engineer", "contract_c2c", "direct", "interviewing", [ 100, 125, "hourly" ], 18, 1,
    "Small team, fast process.",
    [ [ "email", 18, "Founder replied to my note." ],
      [ "call", 14, "Intro call with the founder." ],
      [ "interview", 6, "Code review exercise with the lead engineer." ] ] ],
  [ "Soylent Foods", "Software Engineer", "full_time", "agency", "interviewing", [ 145_000, 170_000, "yearly" ], 21, 7,
    "Agency is coordinating the schedule.",
    [ [ "email", 21, "Agency submitted me." ],
      [ "interview", 10, "Hiring manager interview." ] ] ],
  [ "Cyberdyne Systems", "Staff Engineer", "full_time", "network", "offer", [ 210_000, 235_000, "yearly" ], 40, 2,
    "Offer received; deciding by the end of the week.",
    [ [ "interview", 22, "Onsite loop." ],
      [ "call", 8, "Call with the hiring manager." ],
      [ "email", 3, "Received the written offer." ],
      [ "note", 1, "Comparing against other options; asked about equity details." ] ] ],
  [ "Massive Dynamic", "Senior Backend Engineer", "contract_w2", "recruiter", "closed", [ 90, 105, "hourly" ], 45, nil,
    "Role was filled internally.",
    [ [ "email", 45, "Recruiter reached out." ],
      [ "interview", 30, "Technical screen." ],
      [ "email", 15, "Told the role was filled; closing this out." ] ],
    "posting_closed" ],
  [ "Oscorp Labs", "Rails Engineer", "full_time", "job_board", "closed", nil, 30, nil,
    "Pay range was not listed, and the role was onsite only.",
    [ [ "email", 30, "Applied." ],
      [ "note", 20, "Passed: onsite five days a week." ] ],
    "withdrew" ]
]

opportunities.each do |company, role, kind, source, status, pay, contacted_ago, follow_up_in, notes, activities, closed_reason|
  pay_min, pay_max, pay_unit = pay
  opportunity = Opportunity.create!(
    company: company, role: role, kind: kind, source: source, status: status, closed_reason: closed_reason,
    pay_min: pay_min, pay_max: pay_max, pay_unit: pay_unit || "yearly",
    contacted_on: contacted_ago && today - contacted_ago,
    follow_up_on: follow_up_in && today + follow_up_in,
    notes: notes,
    url: "https://example.com/careers/#{company.parameterize}"
  )

  activities.each do |activity_kind, days_ago, body|
    opportunity.activities.create!(kind: activity_kind, occurred_on: today - days_ago, body: body)
  end
end

# Application details for a few of the applied-or-later records, so the detail page shows them.
{
  "Globex Payments" => { application_channel: "form", resume_version: "backend-2026-11" },
  "Initech Cloud" => { application_channel: "ats", resume_version: "fullstack-2026-11", contact_name: "Dana Whitfield" },
  "Stark Robotics" => { application_channel: "referral", resume_version: "senior-2026-11", contact_name: "Pat Alvarez" },
  "Hooli Maps" => { application_channel: "email", resume_version: "platform-2026-11", contact_name: "Sam Okafor" }
}.each { |company, details| Opportunity.find_by!(company: company).update!(details) }
