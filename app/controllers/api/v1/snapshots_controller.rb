module Api
  module V1
    class SnapshotsController < Api::BaseController
      # POST /api/v1/snapshots/capture
      # Triggers an immediate snapshot capture for an endpoint.
      # Body: { endpoint_id: integer }
      def capture
        endpoint = find_endpoint(params[:endpoint_id])
        return unless endpoint

        result = Snapshots::CaptureService.new(endpoint: endpoint, triggered_by: "ci").call

        if result.success?
          render json: {
            snapshot_id: result.snapshot.id,
            taken_at: result.snapshot.taken_at,
            status_code: result.snapshot.status_code
          }, status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def find_endpoint(id)
        endpoint = current_user.projects.flat_map(&:endpoints).find { |e| e.id.to_s == id.to_s }
        unless endpoint
          render json: { error: "Endpoint not found" }, status: :not_found
          return nil
        end
        endpoint
      end
    end
  end
end
