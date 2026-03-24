require "test_helper"

class Api::V1::EndpointsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user     = create(:user)
    @project  = create(:project, user: @user)
    @endpoint = create(:endpoint, project: @project)
    @snapshot = create(:snapshot, endpoint: @endpoint, taken_at: 1.hour.ago)
  end

  test "returns 401 without token" do
    patch baseline_api_v1_endpoint_url(@endpoint), as: :json
    assert_response :unauthorized
  end

  test "sets baseline to latest snapshot" do
    patch baseline_api_v1_endpoint_url(@endpoint),
          headers: { "Authorization" => "Bearer #{@user.api_token}" },
          as: :json

    assert_response :ok
    json = response.parsed_body
    assert_equal @endpoint.id, json["endpoint_id"]
    assert_equal @snapshot.id, json["baseline_snapshot_id"]
    assert_equal @snapshot.id, @endpoint.reload.baseline_snapshot_id
  end

  test "returns 422 when no snapshots exist" do
    endpoint_no_snaps = create(:endpoint, project: @project)

    patch baseline_api_v1_endpoint_url(endpoint_no_snaps),
          headers: { "Authorization" => "Bearer #{@user.api_token}" },
          as: :json

    assert_response :unprocessable_entity
  end

  test "returns 404 for endpoint not owned by user" do
    other_user    = create(:user)
    other_project = create(:project, user: other_user)
    other_endpoint = create(:endpoint, project: other_project)

    patch baseline_api_v1_endpoint_url(other_endpoint),
          headers: { "Authorization" => "Bearer #{@user.api_token}" },
          as: :json

    assert_response :not_found
  end
end
