require "test_helper"

class FeatureClassesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @feature_class = feature_classes(:one)
  end

  test "should get index" do
    get feature_classes_url
    assert_response :success
  end

  test "should get new" do
    get new_feature_class_url
    assert_response :success
  end

  test "should create feature_class" do
    assert_difference("FeatureClass.count") do
      post feature_classes_url, params: { feature_class: {  } }
    end

    assert_redirected_to feature_class_url(FeatureClass.last)
  end

  test "should show feature_class" do
    get feature_class_url(@feature_class)
    assert_response :success
  end

  test "should get edit" do
    get edit_feature_class_url(@feature_class)
    assert_response :success
  end

  test "should update feature_class" do
    patch feature_class_url(@feature_class), params: { feature_class: {  } }
    assert_redirected_to feature_class_url(@feature_class)
  end

  test "should destroy feature_class" do
    assert_difference("FeatureClass.count", -1) do
      delete feature_class_url(@feature_class)
    end

    assert_redirected_to feature_classes_url
  end
end
