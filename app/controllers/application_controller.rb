class ApplicationController < ActionController::Base

  OIDC_FLOW_START = "#{ENV['RAILS_RELATIVE_URL_ROOT']}/auth/oidc".freeze

  before_action :authorize_user, except: %w(authentication_callback login not_authorized logout)
  helper_method :current_user

  def authentication_callback
    auth = request.env['omniauth.auth']
    open_id_authorize(auth)
    redirect_to session[:return_to] || root_path
  rescue AuthenticationException => _e
    redirect_to application_not_authorized_path
  end

  def login
    render :login, layout: nil
  end

  def logout
    reset_session
    redirect_to root_path
  end

  def not_authorized
  end

  def role
    if request.post?
      session[:roles] = [params['user']['role']]
      redirect_to root_path
    else
      # display page
    end
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:error] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  private

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
    first_name = auth.dig('extra', 'raw_info', 'first_name')
    last_name = auth.dig('extra', 'raw_info', 'last_name')
    email_address = auth.dig('extra', 'raw_info', 'email')
    roles = auth.dig('extra', 'raw_info', 'roles')

    raise AuthorizationException, 'No roles assigned.' if roles.empty?

    session[:email_address] = email_address
    session[:roles] = roles
  rescue AuthorizationExceptionException => _e
    redirect_to application_not_authorized_path
  end

  def current_user
    return nil if session[:email_address].blank? || session[:roles].nil?

    @current_user ||= AuthorizedUser.new(session[:email_address], session[:roles])
  end

  class AuthenticationException < StandardError; end
  class AuthorizationException < StandardError; end
end
