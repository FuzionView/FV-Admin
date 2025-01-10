require "test_helper"

class FeatureStatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @feature_status = feature_statuses(:one)
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
    get feature_statuses_url
    assert_response :success
  end

  test "should get new" do
    get new_feature_status_url
    assert_response :success
  end

  test "should create feature_status" do
    assert_difference("FeatureStatus.count") do
      post feature_statuses_url, params: { feature_status: { id: 3, status: 'Status 3' } }
    end

    assert_redirected_to feature_statuses_url
  end

  test "should get edit" do
    get edit_feature_status_url(@feature_status)
    assert_response :success
  end

  test "should update feature_status" do
    patch feature_status_url(@feature_status), params: { feature_status: {  } }
    assert_redirected_to feature_statuses_url
  end

  test "should destroy feature_status" do
    assert_difference("FeatureStatus.count", -1) do
      delete feature_status_url(@feature_status)
    end

    assert_redirected_to feature_statuses_url
  end
end
