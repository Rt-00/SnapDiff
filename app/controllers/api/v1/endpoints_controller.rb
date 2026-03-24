module Api
  module V1
    class EndpointsController < Api::BaseController
      before_action :set_endpoint

      # PATCH /api/v1/endpoints/:id/baseline
      # Sets the latest snapshot as the baseline for the endpoint.
      def baseline
        latest = @endpoint.snapshots.order(taken_at: :desc).first
        unless latest
          render json: { error: "No snapshots found for this endpoint" }, status: :unprocessable_entity
          return
        end

        @endpoint.update!(baseline_snapshot: latest)
        render json: {
          endpoint_id: @endpoint.id,
          baseline_snapshot_id: @endpoint.baseline_snapshot_id
        }
      end

      private

      def set_endpoint
        @endpoint = current_user.projects.flat_map(&:endpoints).find { |e| e.id.to_s == params[:id].to_s }
        render json: { error: "Endpoint not found" }, status: :not_found unless @endpoint
      end
    end
  end
end
