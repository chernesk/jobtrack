module Api
  module V1
    class OpportunitiesController < BaseController
      def index
        opportunities = Opportunity.search(params[:q].to_s)
          .with_status(params[:status].to_s).with_kind(params[:kind].to_s)
          .by_follow_up(params[:dir].to_s == "desc" ? :desc : :asc)

        render json: { opportunities: opportunities.map(&:as_props) }
      end

      def show
        render json: { opportunity: find_opportunity.as_props }
      end

      def create
        opportunity = Opportunity.new(opportunity_params)

        if opportunity.save
          render json: { opportunity: opportunity.as_props }, status: :created, location: api_v1_opportunity_url(opportunity)
        else
          render_invalid(opportunity)
        end
      end

      def update
        opportunity = find_opportunity

        if opportunity.update(opportunity_params)
          render json: { opportunity: opportunity.as_props }
        else
          render_invalid(opportunity)
        end
      end

      private

      def find_opportunity
        Opportunity.find(params[:id])
      end

      # Same editable fields as the web form; `position` stays owned by the board.
      # Bodies look like { "opportunity": { "company": "...", ... } }.
      def opportunity_params
        permitted = params.expect(opportunity: Opportunity::EDITABLE_ATTRIBUTES)
        Opportunity::NULLABLE_ENUMS.each { |name| permitted[name] = permitted[name].presence if permitted.key?(name) }
        permitted
      end

      # Every message per field (the web form shows only the first).
      def render_invalid(record)
        render json: { errors: record.errors.to_hash }, status: :unprocessable_content
      end
    end
  end
end
