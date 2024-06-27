require "application_system_test_case"

class FeatureClassesTest < ApplicationSystemTestCase
  setup do
    @feature_class = feature_classes(:one)
  end

  test "visiting the index" do
    visit feature_classes_url
    assert_selector "h1", text: "Feature classes"
  end

  test "should create feature class" do
    visit feature_classes_url
    click_on "New feature class"

    click_on "Create Feature class"

    assert_text "Feature class was successfully created"
    click_on "Back"
  end

  test "should update Feature class" do
    visit feature_class_url(@feature_class)
    click_on "Edit this feature class", match: :first

    click_on "Update Feature class"

    assert_text "Feature class was successfully updated"
    click_on "Back"
  end

  test "should destroy Feature class" do
    visit feature_class_url(@feature_class)
    click_on "Destroy this feature class", match: :first

    assert_text "Feature class was successfully destroyed"
  end
end
