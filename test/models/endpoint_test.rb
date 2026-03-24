require "test_helper"

class EndpointTest < ActiveSupport::TestCase
  test "valid endpoint" do
    assert build(:endpoint).valid?
  end

  test "invalid without name" do
    endpoint = build(:endpoint, name: nil)
    assert_not endpoint.valid?
    assert_includes endpoint.errors[:name], "can't be blank"
  end

  test "invalid without url" do
    endpoint = build(:endpoint, url: nil)
    assert_not endpoint.valid?
    assert_includes endpoint.errors[:url], "can't be blank"
  end

  test "invalid with non-HTTP url" do
    endpoint = build(:endpoint, url: "ftp://example.com")
    assert_not endpoint.valid?
    assert_includes endpoint.errors[:url], "must be a valid HTTP/HTTPS URL"
  end

  test "invalid with bad http_method" do
    endpoint = build(:endpoint, http_method: "INVALID")
    assert_not endpoint.valid?
    assert_includes endpoint.errors[:http_method], "is not included in the list"
  end

  test "defaults http_method to GET" do
    endpoint = Endpoint.new
    assert_equal "GET", endpoint.http_method
  end

  test "defaults headers to empty hash" do
    endpoint = Endpoint.new
    assert_equal({}, endpoint.headers)
  end

  test "belongs to project" do
    assert_respond_to build(:endpoint), :project
  end

  test "has many snapshots" do
    assert_respond_to build(:endpoint), :snapshots
  end

  test "delegates user to project" do
    endpoint = create(:endpoint)
    assert_equal endpoint.project.user, endpoint.user
  end

  test "all HTTP methods are valid" do
    %w[GET POST PUT PATCH DELETE HEAD OPTIONS].each do |method|
      endpoint = build(:endpoint, http_method: method)
      assert endpoint.valid?, "Expected #{method} to be valid"
    end
  end
end
