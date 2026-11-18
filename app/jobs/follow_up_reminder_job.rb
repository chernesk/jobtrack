# Runs every morning (see config/recurring.yml). A follow-up date passing is not an
# edit, so nothing else would notice that an opportunity has just become due. This
# job brings the `due` flag in line with the rule in `Opportunity.follow_up_due`:
# it turns the flag on for newly due records and off for any that no longer qualify.
#
# It then sends one push notification (see NtfyClient) listing everything due, overdue
# included, so a follow-up does not depend on remembering to open the app. On a day with
# nothing due it sends a quiet "nothing today" instead, so silence never has to be read
# as "it didn't run". A failed send never fails the job, and what happened is logged.
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
    settings = Setting.current
    reason = if !settings.notifications_enabled
      "switched off in settings"
    elsif !NtfyClient.configured?
      "no topic set"
    end
    return Rails.logger.info("FollowUpReminderJob: notifications off (#{reason})") if reason

    due = Opportunity.follow_up_due(today).to_a
    if due.empty? && !settings.notify_when_nothing_due
      return Rails.logger.info("FollowUpReminderJob: 0 due, no notification (nothing-due message is off)")
    end

    sent = due.empty? ? publish_nothing_due(settings) : publish_due(due, today, settings)
    Rails.logger.info("FollowUpReminderJob: #{due.size} due, notification #{sent ? 'sent' : 'failed'}")
  end

  def publish_due(due, today, settings)
    NtfyClient.publish(
      title: "#{due.size} #{'follow-up'.pluralize(due.size)} due",
      message: message_for(due, today, settings),
      click: settings.effective_app_url,
      tags: "bell",
      priority: due.any? { |opportunity| opportunity.follow_up_on < today } ? 4 : 3
    )
  end

  # Low priority: it is a "the check ran" receipt, not something to act on.
  def publish_nothing_due(settings)
    NtfyClient.publish(
      title: "No follow-ups due",
      message: "Nothing due today. The daily check ran.",
      click: settings.effective_app_url,
      tags: "white_check_mark",
      priority: 2
    )
  end

  # One line per opportunity, most overdue first (the scope's order). The "hide names"
  # setting sends only a count, for a public ntfy topic where company names should not travel.
  def message_for(due, today, settings)
    return "Open JobTrack to see them." if settings.effective_hide_names?

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
