require 'openid_connect'

Rails.application.config.middleware.use OmniAuth::Builder do
# OpenIDConnect.debug! if Rails.env.development?
  unless [ENV['OP_HOST'], ENV['OP_CLIENT_ID'], ENV['OP_SECRET_KEY'], ENV['OP_REDIRECT_URI']].all?(&:present?)
    raise "Configuration error. OP_HOST, OP_CLIENT_ID, OP_SECRET_KEY, or OP_REDIRECT_URI variables not set."
  end

  provider :openid_connect, {
    name: :oidc,
    scope: [:openid, :email, :profile, :address],
    response_type: :code,
    'issuer' => "https://#{ENV['OP_HOST']}#{ENV['OP_REALM']}",
    uid_field: 'preferred_username',
    client_options: {
      host: ENV['OP_HOST'],
      identifier: ENV["OP_CLIENT_ID"],
      secret: ENV["OP_SECRET_KEY"],
      authorization_endpoint: "#{ENV['OP_REALM']}#{ENV['OP_AUTH_ENDPOINT']}",
      token_endpoint: "#{ENV['OP_REALM']}#{ENV['OP_TOKEN_ENDPOINT']}",
      userinfo_endpoint: "#{ENV['OP_REALM']}#{ENV['OP_USERINFO_ENDPOINT']}",
      jwks_uri: "https://#{ENV['OP_HOST']}#{ENV['OP_REALM']}#{ENV['OP_JWKS_ENDPOINT']}",
      redirect_uri: ENV['OP_REDIRECT_URI'],
    },
  }
end
