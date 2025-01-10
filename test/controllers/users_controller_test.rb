require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = owners(:one)
    @user = @owner.users.first
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
    get owner_users_url(@owner)
    assert_response :success
  end

  test "should get new" do
    get new_owner_user_url(@owner)
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post owner_users_url(@owner), params: { user: { email_address: @user.email_address } }
    end

    assert_redirected_to owner_users_url(@owner)
  end

  test "should get edit" do
    get edit_owner_user_url(@owner, @user)
    assert_response :success
  end

  test "should update user" do
    patch owner_user_url(@owner, @user), params: { user: { email_address: @user.email_address } }
    assert_redirected_to owner_users_url(@owner)
  end

  test "should destroy user" do
    assert_difference("User.count", -1) do
      delete owner_user_url(@owner, @user)
    end

    assert_redirected_to owner_users_url(@owner)
  end
end
