class DiffReportsController < ApplicationController
  before_action :set_diff_report, only: %i[show]

  def new
    @snapshot_a_id = params[:snapshot_a_id]
    @snapshots_for_select = Snapshot
      .joins(endpoint: :project)
      .where(projects: { user_id: current_user.id })
      .order("projects.name, endpoints.name, snapshots.taken_at DESC")
      .select("snapshots.*, endpoints.name AS endpoint_name, projects.name AS project_name")
  end

  def show; end

  def create
    snapshot_a = find_own_snapshot(params[:snapshot_a_id])
    snapshot_b = find_own_snapshot(params[:snapshot_b_id])

    if snapshot_a.nil? || snapshot_b.nil?
      return redirect_to projects_path, alert: "One or both snapshots not found."
    end

    if snapshot_a.id == snapshot_b.id
      return redirect_to new_diff_report_path(snapshot_a_id: snapshot_a.id),
                         alert: "Please choose two different snapshots to compare."
    end

    report = DiffReport.find_or_create_by!(
      snapshot_a: snapshot_a,
      snapshot_b: snapshot_b
    ) do |r|
      service = Snapshots::DiffService.new(snapshot_b)
      diff_data = service.compute_diff(snapshot_a.response_body, snapshot_b.response_body)
      r.diff_data = diff_data
      r.summary   = service.summarize(diff_data)
    end

    redirect_to diff_report_path(report)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to projects_path, alert: "Could not generate diff: #{e.message}"
  end

  private

  def set_diff_report
    @diff_report = DiffReport.joins(snapshot_a: { endpoint: { project: :user } })
                              .where(users: { id: current_user.id })
                              .find(params[:id])
  end

  def find_own_snapshot(id)
    return nil if id.blank?
    Snapshot.joins(endpoint: { project: :user })
            .where(users: { id: current_user.id })
            .find_by(id: id)
  end
end
