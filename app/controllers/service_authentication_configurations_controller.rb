class ServiceAuthenticationConfigurationsController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_owner, only: %i[index show edit new create update destroy verify]
  before_action :set_service_authentication_configuration, only: %i[show edit update destroy verify]

  def index
    authorize ServiceAuthenticationConfiguration
    redirect_to owner_path(@owner)
  end

  # GET /service_authentication_configurations/1
  def show
    authorize @service_authentication_configuration
  end

  # GET /service_authentication_configurations/new
  def new
    authorize ServiceAuthenticationConfiguration
    @service_authentication_configuration = @owner.service_authentication_configurations.build
  end

  # GET /service_authentication_configurations/1/edit
  def edit
    authorize @service_authentication_configuration
  end

  # POST /service_authentication_configurations
  def create
    authorize ServiceAuthenticationConfiguration
    @service_authentication_configuration = @owner.service_authentication_configurations.build(service_authentication_configuration_params)

    if @service_authentication_configuration.save
      redirect_to owner_service_authentication_configuration_path(@owner, @service_authentication_configuration),
                  notice: t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /service_authentication_configurations/1
  def update
    authorize @service_authentication_configuration
    if @service_authentication_configuration.update(service_authentication_configuration_params)
      redirect_to owner_service_authentication_configuration_path(@owner, @service_authentication_configuration),
                  notice: t('.success'), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /service_authentication_configurations/1
  def destroy
    authorize @service_authentication_configuration
    @service_authentication_configuration.destroy!
    redirect_to owner_url(@owner),
                notice: t('.success'), status: :see_other
  rescue StandardError => _e
    flash[:alert] = t('service_authentication_configurations.destroy.foreign_key_error')
    render 'owners/show', status: :unprocessable_entity
  end

  # POST /owners/:owner_id/service_authentication_configurations/:id/verify
  def verify
    authorize @service_authentication_configuration
    begin
      @service_authentication_configuration.test_configuration
      flash[:notice] = t('.success')
    rescue StandardError => e
      flash[:alert] = t('.failure', message: e.message)
    end
    redirect_to owner_url(@owner)
  end

  private

  def set_owner
    @owner = policy_scope(Owner).find(params[:owner_id])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_service_authentication_configuration
    @service_authentication_configuration = @owner.service_authentication_configurations.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def service_authentication_configuration_params
    params.require(:service_authentication_configuration).permit(:owner_id, :name, :auth_type, :auth_url,
                                                                 :auth_uid, :auth_key)
  end
end
