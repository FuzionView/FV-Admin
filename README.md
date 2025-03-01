# FV-Admin

A Ruby on Rails administration interface for FuzionView

*   Ruby version: 3.0+
*   Rails version: 7.1.x
*   Database: PostgreSQL
*   Authentication: OpenID Connect (Keycloak or other OIDC provider)
*   Authorization: Pundit, based on two externally defined roles set in
    FV_ADMINISTRATOR, FV_DATA_PROVIDER environment variables
*   UI: Bootstrap 5.3

## System dependencies

*   Fuzionview PostgreSQL based implementation
*   Ruby 3.0+

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

## Deployment

*  Phusion Passenger is the recommended production deployment method. 

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
