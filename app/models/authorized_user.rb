class AuthorizedUser
  unless ENV["FV_ADMINISTRATOR"].present? && ENV["FV_DATA_PROVIDER"].present?
    raise "Configuration error. FV_ADMINISTRATOR and/or FV_DATA_PROVIDER environment variables not set."
  end
  ROLES = [
    FV_ADMINISTRATOR = ENV["FV_ADMINISTRATOR"], # Setup Data Providers
    FV_DATA_PROVIDER = ENV["FV_DATA_PROVIDER"]
  ]
  def initialize(email_address, roles)
    @email_address = email_address
    @roles = roles
  end

  def data_providers
    User.where(email_address: @email_address).pluck(:owner_id)
  end

  # def users
  #   User.where(email_address: @email_address).pluck(:id)
  # end

  def administrator?
    @roles.include?(FV_ADMINISTRATOR)
  end

  def data_provider?
    @roles.include?(FV_DATA_PROVIDER)
  end

  def current_role
    @roles.join(", ")
  end
end
