class SnapshotsController < ApplicationController
  before_action :set_endpoint, only: %i[index create]
  before_action :set_snapshot, only: %i[show update]

  def index
    @pagy, @snapshots = paginate(
      @endpoint.snapshots.ordered,
      limit: 20
    )
  end

  def show; end

  def update
    if @snapshot.update(name: params[:name].presence)
      redirect_to snapshot_path(@snapshot), notice: "Snapshot renamed."
    else
      redirect_to snapshot_path(@snapshot), alert: "Could not rename snapshot."
    end
  end

  def create
    result = Snapshots::CaptureService.new(
      endpoint: @endpoint,
      triggered_by: "manual"
    ).call

    if result.success?
      redirect_to snapshot_path(result.snapshot),
                  notice: "Snapshot captured in #{result.snapshot.response_time_ms}ms."
    else
      redirect_to project_endpoint_path(@endpoint.project, @endpoint),
                  alert: result.error
    end
  end

  private

  def set_endpoint
    endpoint_id = params[:endpoint_id] || params.dig(:snapshot, :endpoint_id)
    @endpoint = current_user.projects
                             .joins(:endpoints)
                             .then { Endpoint.where(project: current_user.projects) }
                             .find(endpoint_id)
  end

  def set_snapshot
    @snapshot = Snapshot.joins(endpoint: { project: :user })
                        .where(users: { id: current_user.id })
                        .find(params[:id])
  end
end
