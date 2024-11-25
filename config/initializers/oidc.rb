require 'openid_connect'

Rails.application.config.middleware.use OmniAuth::Builder do
# OpenIDConnect.debug! if Rails.env.development?
  host = ENV['OP_HOST']
  client_id = ENV['OP_CLIENT_ID']
  secret = ENV['OP_SECRET_KEY']
  realm = ENV['OP_REALM']
  redirect = ENV['OP_REDIRECT_URI']

  unless [host, client_id, secret, redirect].all?(&:present?)
    raise "Configuration error. OP_HOST, OP_CLIENT_ID, OP_SECRET_KEY, or OP_REDIRECT_URI variables not set."
  end

  provider :openid_connect, {
    name: :oidc,
    scope: [:openid, :email, :profile, :address],
    response_type: :code,
    'issuer' => "https://#{host}#{realm}",
    uid_field: 'preferred_username',
    client_options: {
      host: host,
      identifier: client_id,
      secret: secret,
      authorization_endpoint: "#{realm}#{ENV['OP_AUTH_ENDPOINT']}",
      token_endpoint: "#{realm}#{ENV['OP_TOKEN_ENDPOINT']}",
      userinfo_endpoint: "#{realm}#{ENV['OP_USERINFO_ENDPOINT']}",
      jwks_uri: "https://#{host}#{realm}#{ENV['OP_JWKS_ENDPOINT']}",
      redirect_uri: ENV['OP_REDIRECT_URI'],
    },
  }
end
