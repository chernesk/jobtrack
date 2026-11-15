class ActivitiesController < ApplicationController
  def create
    opportunity = Opportunity.find(params[:opportunity_id])
    activity = opportunity.activities.build(activity_params)

    if activity.save
      redirect_to opportunity_path(opportunity), notice: "Activity added."
    else
      redirect_to opportunity_path(opportunity), inertia: { errors: activity.errors.to_hash.transform_values(&:first) }
    end
  end

  private

  def activity_params
    params.expect(activity: %i[kind occurred_on body])
  end
end
