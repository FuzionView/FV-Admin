require 'test_helper'

class FeatureClassesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @feature_class = feature_classes(:one)
    OmniAuth.config.test_mode = true
    omni_hash = { uid: '12345',
                  extra: { raw_info: { email: 'bob@example.org',
                                       first_name: 'Bob',
                                       last_name: 'B',
                                       roles: ['Administrator'] } },
                  credentials: { token: 'abcd' } }
    OmniAuth.config.add_mock(:oidc, omni_hash)
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:oidc]
    get '/auth/oidc/callback'
  end

  test 'should get index' do
    get feature_classes_url
    assert_response :success
  end

  test 'should get new' do
    get new_feature_class_url
    assert_response :success
  end

  test 'should create feature_class' do
    assert_difference('FeatureClass.count') do
      post feature_classes_url, params: {
        feature_class: { id: 'id', name: 'test', color_hex: '#ff00ff',
                         color_mapserv: '255 0 255', code: 'test' }
      }
    end

    assert_redirected_to feature_classes_url
  end

  test 'should get edit' do
    get edit_feature_class_url(@feature_class)
    assert_response :success
  end

  test 'should update feature_class' do
    patch feature_class_url(@feature_class), params: { feature_class: { color_mapserv: '255 255 255' } }
    assert_redirected_to feature_classes_url
  end

  test 'should destroy feature_class' do
    assert_difference('FeatureClass.count', -1) do
      delete feature_class_url(@feature_class)
    end

    assert_redirected_to feature_classes_url
  end
end
