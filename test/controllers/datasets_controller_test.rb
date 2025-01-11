require "test_helper"

class DatasetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = owners(:one)
    @dataset = @owner.datasets.first
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


  test "should get new" do
    get new_owner_dataset_url(@owner)
    assert_response :success
  end

  test "should create dataset" do
    assert_difference("Dataset.count") do
      post owner_datasets_url(@owner), params: {
        dataset: { name: 'Name', source_sql: 'select *',
                   source_dataset: 'WFS:http://example.com',
                   source_srs: 'EPSG:26915'
                 }
      }
    end

    assert_redirected_to owner_dataset_url(@owner, Dataset.last)

  end

  test "should show dataset" do
    get owner_dataset_url(@dataset.owner, @dataset)
    assert_response :success
  end

  test "should get edit" do
    get edit_owner_dataset_url(@dataset.owner, @dataset)
    assert_response :success
  end

  test "should update dataset" do
    patch owner_dataset_url(@dataset.owner, @dataset), params: { dataset: {  } }
    assert_redirected_to owner_dataset_url(@dataset.owner, @dataset)
  end

  test "should destroy dataset" do
    assert_difference("Dataset.count", -1) do
      delete owner_dataset_url(@dataset.owner, @dataset)
    end

    assert_redirected_to owner_url(@dataset.owner)
  end
end
