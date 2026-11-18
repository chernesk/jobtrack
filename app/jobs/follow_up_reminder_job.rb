# Runs every morning (see config/recurring.yml). A follow-up date passing is not an
# edit, so nothing else would notice that an opportunity has just become due. This
# job brings the `due` flag in line with the rule in `Opportunity.follow_up_due`:
# it turns the flag on for newly due records and off for any that no longer qualify.
#
# It then sends one push notification (see NtfyClient) listing everything due, overdue
# included, so a follow-up does not depend on remembering to open the app. Nothing is
# sent on a day with nothing due, and a failed send never fails the job.
class FollowUpReminderJob < ApplicationJob
  queue_as :default

  # `today` is a parameter so specs can pick the day; in production it is the current date.
  def perform(today = Date.current)
    due_now = Opportunity.follow_up_due(today).unscope(:order).select(:id)

    marked = Opportunity.where(due: false, id: due_now).update_all(due: true)
    cleared = Opportunity.where(due: true).where.not(id: due_now).update_all(due: false)

    Rails.logger.info("FollowUpReminderJob: #{marked} newly due, #{cleared} cleared")
    notify(today)
    { marked: marked, cleared: cleared }
  end

  private

  MAX_LISTED = 8

  def notify(today)
    due = Opportunity.follow_up_due(today).to_a
    return if due.empty?

    NtfyClient.publish(
      title: "#{due.size} #{'follow-up'.pluralize(due.size)} due",
      message: message_for(due, today),
      click: ENV["APP_URL"],
      tags: "bell",
      priority: due.any? { |opportunity| opportunity.follow_up_on < today } ? 4 : 3
    )
  end

  # One line per opportunity, most overdue first (the scope's order). `NTFY_HIDE_NAMES`
  # sends only a count, for a public ntfy topic where company names should not travel.
  def message_for(due, today)
    return "Open JobTrack to see them." if ENV["NTFY_HIDE_NAMES"].present?

    lines = due.first(MAX_LISTED).map { |opportunity| line_for(opportunity, today) }
    lines << "and #{due.size - MAX_LISTED} more" if due.size > MAX_LISTED
    lines.join("\n")
  end

  def line_for(opportunity, today)
    days = (today - opportunity.follow_up_on).to_i
    when_due = days.zero? ? "due today" : "#{days} #{'day'.pluralize(days)} overdue"
    "#{opportunity.company}, #{opportunity.role} (#{when_due})"
  end
end
