require "test_helper"

class Snapshots::CaptureServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @endpoint = create(:endpoint, url: "https://api.example.com/data", http_method: "GET")
  end

  test "returns success result on valid HTTP response" do
    stub_request(:get, "https://api.example.com/data")
      .to_return(status: 200, body: '{"id":1,"name":"test"}', headers: { "Content-Type" => "application/json" })

    result = Snapshots::CaptureService.new(endpoint: @endpoint).call

    assert result.success?
    assert_not_nil result.snapshot
    assert_equal 200, result.snapshot.status_code
    assert_equal({ "id" => 1, "name" => "test" }, result.snapshot.response_body)
    assert_equal "manual", result.snapshot.triggered_by
  end

  test "accepts triggered_by parameter" do
    stub_request(:get, "https://api.example.com/data")
      .to_return(status: 200, body: "{}", headers: {})

    result = Snapshots::CaptureService.new(endpoint: @endpoint, triggered_by: "ci").call

    assert result.success?
    assert_equal "ci", result.snapshot.triggered_by
  end

  test "handles non-JSON response body gracefully" do
    stub_request(:get, "https://api.example.com/data")
      .to_return(status: 200, body: "plain text response", headers: {})

    result = Snapshots::CaptureService.new(endpoint: @endpoint).call

    assert result.success?
    assert_equal({ "_raw" => "plain text response" }, result.snapshot.response_body)
  end

  test "captures error response (e.g. 404)" do
    stub_request(:get, "https://api.example.com/data")
      .to_return(status: 404, body: '{"error":"not found"}', headers: {})

    result = Snapshots::CaptureService.new(endpoint: @endpoint).call

    assert result.success?
    assert_equal 404, result.snapshot.status_code
  end

  test "returns error result on connection failure" do
    stub_request(:get, "https://api.example.com/data")
      .to_raise(Faraday::ConnectionFailed.new("connection refused"))

    result = Snapshots::CaptureService.new(endpoint: @endpoint).call

    assert_not result.success?
    assert_includes result.error, "HTTP request failed"
    assert_nil result.snapshot
  end

  test "sends custom headers to the request" do
    @endpoint.update!(headers: { "Authorization" => "Bearer secret" })

    stub_request(:get, "https://api.example.com/data")
      .with(headers: { "Authorization" => "Bearer secret" })
      .to_return(status: 200, body: "{}", headers: {})

    result = Snapshots::CaptureService.new(endpoint: @endpoint).call
    assert result.success?
  end

  test "does not send body for GET requests" do
    stub_request(:get, "https://api.example.com/data")
      .with(body: nil)
      .to_return(status: 200, body: "{}", headers: {})

    result = Snapshots::CaptureService.new(endpoint: @endpoint).call
    assert result.success?
  end

  test "POST request sends body" do
    endpoint = create(:endpoint, url: "https://api.example.com/data",
                                 http_method: "POST",
                                 body: { "key" => "value" })

    stub_request(:post, "https://api.example.com/data")
      .with(body: '{"key":"value"}')
      .to_return(status: 201, body: '{"created":true}', headers: {})

    result = Snapshots::CaptureService.new(endpoint: endpoint).call
    assert result.success?
    assert_equal 201, result.snapshot.status_code
  end

  test "enqueues DiffJob after successful capture" do
    stub_request(:get, "https://api.example.com/data")
      .to_return(status: 200, body: "{}", headers: {})

    assert_enqueued_with(job: DiffJob) do
      Snapshots::CaptureService.new(endpoint: @endpoint).call
    end
  end
end
