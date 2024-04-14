require 'openid_connect'

Rails.application.config.middleware.use OmniAuth::Builder do
# OpenIDConnect.debug! if Rails.env.development?

  provider :openid_connect, {
    name: :oidc,
    scope: [:openid, :email, :profile, :address],
    response_type: :code,
    'issuer' => 'https://sso.sharedgeo.org/realms/SharedGeo',
    uid_field: 'preferred_username',
    client_options: {
      host: 'sso.sharedgeo.org',
      identifier: ENV["OP_CLIENT_ID"],
      secret: ENV["OP_SECRET_KEY"],
      authorization_endpoint: '/realms/SharedGeo/protocol/openid-connect/auth',
      token_endpoint: '/realms/SharedGeo/protocol/openid-connect/token',
      userinfo_endpoint: '/realms/SharedGeo/protocol/openid-connect/userinfo',
      jwks_uri: 'https://sso.sharedgeo.org/realms/SharedGeo/protocol/openid-connect/certs',
      redirect_uri: "#{ENV['OP_REDIRECT_URI']}",
    },
  }
end
