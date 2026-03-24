require "test_helper"

class Api::V1::SnapshotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user     = create(:user)
    @project  = create(:project, user: @user)
    @endpoint = create(:endpoint, project: @project, url: "https://api.example.com/data")
  end

  test "returns 401 without token" do
    post capture_api_v1_snapshots_url, params: { endpoint_id: @endpoint.id }, as: :json
    assert_response :unauthorized
  end

  test "returns 401 with invalid token" do
    post capture_api_v1_snapshots_url,
         params: { endpoint_id: @endpoint.id },
         headers: { "Authorization" => "Bearer badtoken" },
         as: :json
    assert_response :unauthorized
  end

  test "captures snapshot for owned endpoint" do
    stub_request(:get, @endpoint.url)
      .to_return(status: 200, body: '{"status":"ok"}', headers: {})

    assert_difference "Snapshot.count", 1 do
      post capture_api_v1_snapshots_url,
           params: { endpoint_id: @endpoint.id },
           headers: { "Authorization" => "Bearer #{@user.api_token}" },
           as: :json
    end

    assert_response :created
    json = response.parsed_body
    assert json["snapshot_id"].present?
    assert json["taken_at"].present?
  end

  test "returns 404 for endpoint not owned by user" do
    other_user    = create(:user)
    other_project = create(:project, user: other_user)
    other_endpoint = create(:endpoint, project: other_project)

    post capture_api_v1_snapshots_url,
         params: { endpoint_id: other_endpoint.id },
         headers: { "Authorization" => "Bearer #{@user.api_token}" },
         as: :json

    assert_response :not_found
  end

  test "sets triggered_by to ci" do
    stub_request(:get, @endpoint.url)
      .to_return(status: 200, body: '{}', headers: {})

    post capture_api_v1_snapshots_url,
         params: { endpoint_id: @endpoint.id },
         headers: { "Authorization" => "Bearer #{@user.api_token}" },
         as: :json

    assert_response :created
    assert_equal "ci", Snapshot.last.triggered_by
  end
end
