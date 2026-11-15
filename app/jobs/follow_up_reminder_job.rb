# Runs every morning (see config/recurring.yml). A follow-up date passing is not an
# edit, so nothing else would notice that an opportunity has just become due. This
# job brings the `due` flag in line with the rule in `Opportunity.follow_up_due`:
# it turns the flag on for newly due records and off for any that no longer qualify.
class FollowUpReminderJob < ApplicationJob
  queue_as :default

  # `today` is a parameter so specs can pick the day; in production it is the current date.
  def perform(today = Date.current)
    due_now = Opportunity.follow_up_due(today).unscope(:order).select(:id)

    marked = Opportunity.where(due: false, id: due_now).update_all(due: true)
    cleared = Opportunity.where(due: true).where.not(id: due_now).update_all(due: false)

    Rails.logger.info("FollowUpReminderJob: #{marked} newly due, #{cleared} cleared")
    { marked: marked, cleared: cleared }
  end
end
