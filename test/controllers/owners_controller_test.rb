require "test_helper"

class OwnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = owners(:one)
    OmniAuth.config.test_mode = true
    omni_hash =  {  uid: "12345",
                    extra: { raw_info: { email: "bob@example.org",
                                         first_name: 'Bob',
                                         last_name: 'B',
                                         roles: ['Administrator'] }},
                  credentials: {token: "abcd"} }
    OmniAuth.config.add_mock(:oidc, omni_hash)
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:oidc]
    get "/auth/oidc/callback"
  end

  test "should get index" do
    get owners_url
    assert_response :success
  end

  test "should get new" do
    get new_owner_url
    assert_response :success
  end

  test "should create owner" do
    assert_difference("Owner.count") do
      post owners_url, params: { owner: { name: 'Owner 3' } }
    end

    assert_redirected_to owner_url(Owner.last)
  end

  test "should show owner" do
    get owner_url(@owner)
    assert_response :success
  end

  test "should get edit" do
    get edit_owner_url(@owner)
    assert_response :success
  end

  test "should update owner" do
    patch owner_url(@owner), params: { owner: {  } }
    assert_redirected_to owner_url(@owner)
  end

  test "should destroy owner" do
    assert_difference("Owner.count", -1) do
      delete owner_url(@owner)
    end

    assert_redirected_to owners_url
  end
end
