class EndpointsController < ApplicationController
  before_action :set_project
  before_action :set_endpoint, only: %i[show edit update destroy set_baseline]

  def show
    @snapshots = @endpoint.snapshots.order(taken_at: :desc).limit(10)
  end

  def new
    @endpoint = @project.endpoints.build
  end

  def create
    @endpoint = @project.endpoints.build(endpoint_params)
    if @endpoint.save
      redirect_to project_endpoint_path(@project, @endpoint), notice: "Endpoint added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @endpoint.update(endpoint_params)
      redirect_to project_endpoint_path(@project, @endpoint), notice: "Endpoint updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @endpoint.destroy
    redirect_to project_path(@project), notice: "Endpoint deleted."
  end

  def set_baseline
    snapshot = @endpoint.snapshots.find(params[:snapshot_id])
    @endpoint.update!(baseline_snapshot: snapshot)
    redirect_to project_endpoint_path(@project, @endpoint), notice: "Baseline snapshot set."
  rescue ActiveRecord::RecordNotFound
    redirect_to project_endpoint_path(@project, @endpoint), alert: "Snapshot not found."
  end

  private

  def set_project
    @project = current_user.projects.find(params[:project_id])
  end

  def set_endpoint
    @endpoint = @project.endpoints.find(params[:id])
  end

  def endpoint_params
    params.require(:endpoint).permit(:name, :url, :http_method, :schedule,
                                     headers: {}, body: {})
  end
end
