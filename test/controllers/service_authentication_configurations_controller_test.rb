require "test_helper"

class ServiceAuthenticationConfigurationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = owners(:one)
    @service_authentication_configuration = @owner.service_authentication_configurations.first
    OmniAuth.config.test_mode = true
    omni_hash = { uid: "12345",
                  extra: { raw_info: { email: "bob@example.org",
                                       first_name: "Bob",
                                       last_name: "B",
                                       roles: [ "Administrator" ] } },
                  credentials: { token: "abcd" } }
    OmniAuth.config.add_mock(:oidc, omni_hash)
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:oidc]
    get "/auth/oidc/callback"
  end

  test "should get new" do
    get new_owner_service_authentication_configuration_url(@owner)
    assert_response :success
  end

  test "should create service_authentication_configuration" do
    assert_difference("ServiceAuthenticationConfiguration.count") do
      post owner_service_authentication_configurations_url(@owner),
           params: { service_authentication_configuration: { name: @service_authentication_configuration.name,
                                                             auth_type: @service_authentication_configuration.auth_type,
                                                             auth_uid: @service_authentication_configuration.auth_uid,
                                                             auth_key: @service_authentication_configuration.auth_key,
                                                             auth_url: @service_authentication_configuration.auth_url,
                                                             owner_id: @service_authentication_configuration.owner_id } }
    end

    assert_redirected_to owner_service_authentication_configuration_url(
      @owner, ServiceAuthenticationConfiguration.last)
  end

  test "should show service_authentication_configuration" do
    get owner_service_authentication_configuration_url(
      @owner, @service_authentication_configuration
    )
    assert_response :success
  end

  test "should get edit" do
    get edit_owner_service_authentication_configuration_url(
      @owner, @service_authentication_configuration
    )
    assert_response :success
  end

  test "should update service_authentication_configuration" do
    patch owner_service_authentication_configuration_url(@owner, @service_authentication_configuration),
      params: { service_authentication_configuration: { name: @service_authentication_configuration.name,
                                                       auth_type: @service_authentication_configuration.auth_type,
                                                       auth_uid: @service_authentication_configuration.auth_uid,
                                                       auth_key: @service_authentication_configuration.auth_key,
                                                       auth_url: @service_authentication_configuration.auth_url,
                                                       owner_id: @service_authentication_configuration.owner_id } }
    assert_redirected_to owner_service_authentication_configuration_url(@owner,
                                                                        @service_authentication_configuration)
  end

  test "should destroy service_authentication_configuration" do
    assert_difference("ServiceAuthenticationConfiguration.count", -1) do
      delete owner_service_authentication_configuration_url(
        @owner, @service_authentication_configuration
      )
    end

    assert_redirected_to owner_url(@owner)
  end
end
