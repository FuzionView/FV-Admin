require "test_helper"

class AccuracyClassesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @accuracy_class = accuracy_classes(:one)
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

  test "should get index" do
    get accuracy_classes_url
    assert_response :success
  end

  test "should get new" do
    get new_accuracy_class_url
    assert_response :success
  end

  test "should create accuracy_class" do
    assert_difference("AccuracyClass.count") do
      post accuracy_classes_url, params: { accuracy_class: { id: 1, name: "AC3" } }
    end

    assert_redirected_to accuracy_classes_url
  end

  test "should get edit" do
    get edit_accuracy_class_url(@accuracy_class)
    assert_response :success
  end

  test "should update accuracy_class" do
    patch accuracy_class_url(@accuracy_class), params: { accuracy_class: { name: "AC11" } }
    assert_redirected_to accuracy_classes_url
  end

  test "should destroy accuracy_class" do
    assert_difference("AccuracyClass.count", -1) do
      delete accuracy_class_url(@accuracy_class)
    end

    assert_redirected_to accuracy_classes_url
  end
end
