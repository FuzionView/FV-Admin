class ApplicationController < ActionController::Base
  OIDC_FLOW_START = "#{ENV['RAILS_RELATIVE_URL_ROOT']}/auth/oidc".freeze

  before_action :authorize_user, except: %w[authentication_callback login not_authorized logout]
  helper_method :current_user

  def authentication_callback
    auth = request.env["omniauth.auth"]
    open_id_authorize(auth)
    redirect_to session[:return_to] || root_path
  rescue AuthenticationException => _e
    redirect_to application_not_authorized_path
  end

  def login
    render :login
  end

  def logout
    id_token = session[:id_token]
    reset_session
    logout_url = "https://#{ENV['OP_HOST']}#{ENV['OP_REALM']}#{ENV['OP_LOGOUT_ENDPOINT']}"
    redirect_to "#{logout_url}?id_token_hint=#{id_token}&post_logout_redirect_uri=#{root_url}", allow_other_host: true
  end

  def not_authorized; end

  def role
    if request.post?
      session[:roles] = [ params["user"]["role"] ]
      redirect_to root_path
    else
      # display page
    end
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:error] = t("application.unauthorized")
    redirect_back(fallback_location: root_path)
  end

  def authorize_user
    return true if current_user.present?

    session[:return_to] = request.fullpath if request.get?
    if request.xhr?
      head(:unauthorized) && return
    else
      redirect_to application_login_path
    end
  end

  def open_id_authorize(auth)
    id_token = auth.dig("credentials", "id_token")
    auth.dig("extra", "raw_info", "first_name")
    auth.dig("extra", "raw_info", "last_name")
    email_address = auth.dig("extra", "raw_info", "email")
    roles = auth.dig("extra", "raw_info", "roles")

    raise AuthorizationException, t("application.no_roles_assigned") if roles.empty?

    session[:id_token] = id_token
    session[:email_address] = email_address
    session[:roles] = roles
  rescue AuthorizationException => _e
    redirect_to application_not_authorized_path
  end

  def current_user
    return nil if session[:email_address].blank? || session[:roles].nil?

    @current_user ||= AuthorizedUser.new(session[:email_address], session[:roles])
  end

  class AuthenticationException < StandardError; end
  class AuthorizationException < StandardError; end
end
