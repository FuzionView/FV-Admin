require "application_system_test_case"

class FeatureStatusesTest < ApplicationSystemTestCase
  setup do
    @feature_status = feature_statuses(:one)
  end

  test "visiting the index" do
    visit feature_statuses_url
    assert_selector "h1", text: "Feature statuses"
  end

  test "should create feature status" do
    visit feature_statuses_url
    click_on "New feature status"

    click_on "Create Feature status"

    assert_text "Feature status was successfully created"
    click_on "Back"
  end

  test "should update Feature status" do
    visit feature_status_url(@feature_status)
    click_on "Edit this feature status", match: :first

    click_on "Update Feature status"

    assert_text "Feature status was successfully updated"
    click_on "Back"
  end

  test "should destroy Feature status" do
    visit feature_status_url(@feature_status)
    click_on "Destroy this feature status", match: :first

    assert_text "Feature status was successfully destroyed"
  end
end
