require "test_helper"

class SnapshotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user     = create(:user)
    @project  = create(:project, user: @user)
    @endpoint = create(:endpoint, project: @project)
    @snapshot = create(:snapshot, endpoint: @endpoint)
    sign_in_as(@user)
  end

  test "GET /snapshots lists snapshots for endpoint" do
    get snapshots_path(endpoint_id: @endpoint.id)
    assert_response :success
  end

  test "GET /snapshots/:id shows a snapshot" do
    get snapshot_path(@snapshot)
    assert_response :success
    assert_match @snapshot.status_code.to_s, response.body
  end

  test "GET /snapshots/:id for wrong user returns 404" do
    other_snapshot = create(:snapshot)
    get snapshot_path(other_snapshot)
    assert_response :not_found
  end

  test "POST /snapshots triggers capture and redirects to snapshot" do
    stub_request(:get, @endpoint.url)
      .to_return(status: 200, body: '{"ok":true}', headers: {})

    assert_difference "Snapshot.count", 1 do
      post snapshots_path, params: { snapshot: { endpoint_id: @endpoint.id } }
    end
    assert_redirected_to snapshot_path(Snapshot.last)
  end

  test "POST /snapshots with failed HTTP shows error" do
    stub_request(:get, @endpoint.url)
      .to_raise(Faraday::ConnectionFailed.new("refused"))

    post snapshots_path, params: { snapshot: { endpoint_id: @endpoint.id } }
    assert_redirected_to project_endpoint_path(@project, @endpoint)
    assert_not_nil flash[:alert]
  end
end
