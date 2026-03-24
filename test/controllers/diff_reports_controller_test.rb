require "test_helper"

class DiffReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user      = create(:user)
    @project   = create(:project, user: @user)
    @endpoint  = create(:endpoint, project: @project)
    @snapshot_a = create(:snapshot, endpoint: @endpoint,
                          response_body: { "name" => "Alice" },
                          taken_at: 1.hour.ago)
    @snapshot_b = create(:snapshot, endpoint: @endpoint,
                          response_body: { "name" => "Bob" },
                          taken_at: Time.current)
    sign_in_as(@user)
  end

  test "GET /diff_reports/new shows compare form" do
    get new_diff_report_path
    assert_response :success
  end

  test "GET /diff_reports/new with snapshot_a_id pre-fills the form" do
    get new_diff_report_path(snapshot_a_id: @snapshot_a.id)
    assert_response :success
    assert_match @snapshot_a.id.to_s, response.body
  end

  test "POST /diff_reports creates a report and redirects to show" do
    assert_difference "DiffReport.count", 1 do
      post diff_reports_path, params: {
        snapshot_a_id: @snapshot_a.id,
        snapshot_b_id: @snapshot_b.id
      }
    end
    assert_redirected_to diff_report_path(DiffReport.last)
  end

  test "POST /diff_reports with same snapshot IDs shows error" do
    post diff_reports_path, params: {
      snapshot_a_id: @snapshot_a.id,
      snapshot_b_id: @snapshot_a.id
    }
    assert_redirected_to new_diff_report_path(snapshot_a_id: @snapshot_a.id)
    assert_equal "Please choose two different snapshots to compare.", flash[:alert]
  end

  test "POST /diff_reports with invalid ids redirects with alert" do
    post diff_reports_path, params: {
      snapshot_a_id: 99999,
      snapshot_b_id: 99998
    }
    assert_redirected_to projects_path
    assert_not_nil flash[:alert]
  end

  test "GET /diff_reports/:id shows report" do
    report = DiffReport.create!(
      snapshot_a: @snapshot_a,
      snapshot_b: @snapshot_b,
      diff_data: { added: [], removed: [], changed: [ { path: "name", old: "Alice", new: "Bob" } ] },
      summary: "1 changed"
    )
    get diff_report_path(report)
    assert_response :success
    assert_match "1 changed", response.body
  end

  test "GET /diff_reports/:id for another user's report returns 404" do
    other_user = create(:user)
    other_project = create(:project, user: other_user)
    other_endpoint = create(:endpoint, project: other_project)
    other_snap_a = create(:snapshot, endpoint: other_endpoint)
    other_snap_b = create(:snapshot, endpoint: other_endpoint)
    other_report = DiffReport.create!(
      snapshot_a: other_snap_a,
      snapshot_b: other_snap_b,
      diff_data: {},
      summary: "No changes"
    )
    get diff_report_path(other_report)
    assert_response :not_found
  end
end
