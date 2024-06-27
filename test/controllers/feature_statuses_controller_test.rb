require "test_helper"

class FeatureStatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @feature_status = feature_statuses(:one)
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
      post feature_statuses_url, params: { feature_status: {  } }
    end

    assert_redirected_to feature_status_url(FeatureStatus.last)
  end

  test "should show feature_status" do
    get feature_status_url(@feature_status)
    assert_response :success
  end

  test "should get edit" do
    get edit_feature_status_url(@feature_status)
    assert_response :success
  end

  test "should update feature_status" do
    patch feature_status_url(@feature_status), params: { feature_status: {  } }
    assert_redirected_to feature_status_url(@feature_status)
  end

  test "should destroy feature_status" do
    assert_difference("FeatureStatus.count", -1) do
      delete feature_status_url(@feature_status)
    end

    assert_redirected_to feature_statuses_url
  end
end
