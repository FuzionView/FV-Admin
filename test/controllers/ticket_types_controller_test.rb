require "test_helper"

class TicketTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ticket_type = ticket_types(:one)
    OmniAuth.config.test_mode = true
    omni_hash =  {  uid: "12345",
                    extra: { raw_info: { email: "bob@example.org",
                                         first_name: "Bob",
                                         last_name: "B",
                                         roles: [ "Administrator" ] } },
                  credentials: { token: "abcd" } }
    OmniAuth.config.add_mock(:oidc, omni_hash)
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:oidc]
    get "/auth/oidc/callback"
  end

  test "should get index" do
    get ticket_types_url
    assert_response :success
  end

  test "should get new" do
    get new_ticket_type_url
    assert_response :success
  end

  test "should create ticket_type" do
    assert_difference("TicketType.count") do
      post ticket_types_url, params: { ticket_type: { id: "normal", description: "Normal", color_mapserv: "0 0 255", color_hex: "#0000ff" } }
    end

    assert_redirected_to ticket_types_url
  end

  test "should get edit" do
    get edit_ticket_type_url(@ticket_type)
    assert_response :success
  end

  test "should update ticket_type" do
    patch ticket_type_url(@ticket_type), params: { ticket_type: {} }
    assert_redirected_to ticket_types_url
  end

  test "should destroy ticket_type" do
    assert_difference("TicketType.count", -1) do
      delete ticket_type_url(@ticket_type)
    end

    assert_redirected_to ticket_types_url
  end
end
