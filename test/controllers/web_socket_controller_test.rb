require "test_helper"

class WebSocketControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get web_socket_index_url
    assert_response :success
  end
end
