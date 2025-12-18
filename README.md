# FV-Admin

[![Ruby on Rails CI](https://github.com/FuzionView/FV-Admin/actions/workflows/rubyonrails.yml/badge.svg?branch=main)](https://github.com/FuzionView/FV-Admin/actions/workflows/rubyonrails.yml)

A Ruby on Rails administration interface for FuzionView

*   Ruby version: 3.3+
*   Rails version: 8.1.x
*   Database: PostgreSQL
*   Authentication: OpenID Connect (Keycloak or other OIDC provider)
*   Authorization: Pundit, based on two externally defined roles set in
    FV_ADMINISTRATOR, FV_DATA_PROVIDER environment variables
*   UI: Bootstrap 5.3

## System dependencies

*   Fuzionview PostgreSQL based implementation
*   Ruby 3.3+

## Configuration

*   Rename `env_example` to `.env` and fill in the required environment variables:

    ```bash
    SECRET_KEY_BASE=

    PG_DB=
    PG_USER=
    PG_PASS=
    PG_HOST=
    PG_PORT=

    OP_CLIENT_ID=
    OP_SECRET_KEY=
    OP_REDIRECT_URI=
    OP_HOST=
    OP_REALM=
    OP_AUTH_ENDPOINT="/protocol/openid-connect/auth"
    OP_TOKEN_ENDPOINT="/protocol/openid-connect/token"
    OP_USERINFO_ENDPOINT="/protocol/openid-connect/userinfo"
    OP_JWKS_ENDPOINT="/protocol/openid-connect/certs"
    OP_LOGOUT_ENDPOINT="/protocol/openid-connect/logout"

    FV_ADMINISTRATOR=Administrator
    FV_DATA_PROVIDER="Data Provider"

    TEST_TICKET_URL=https://localhost/api/tickets/
    ```
*  Most text in the application is externalized and can be updated in config/locales/en.yml.

## Deployment

*  Phusion Passenger is the recommended production deployment method. 
*  Precompile assets in production `RAILS_ENV=production RAILS_RELATIVE_URL_ROOT=/admin rails assets:precompile`

## Development

### Development Setup

1.  Clone the repository.
2.  Install dependencies: `bundle install`
3.  Start the server: `bin/rails server`

### Running tests

*   `RAILS_ENV=test bundle exec rails db:drop db:create db:schema:load`
*   `bin/rails test`

### Migrations

*   `bin/rails db:migrate`

### License

The files in this project are released under the [MIT](LICENSE.txt) license.
