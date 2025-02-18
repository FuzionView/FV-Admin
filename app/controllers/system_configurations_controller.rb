class SystemConfigurationsController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_sys_config, only: %i[show edit update]
  
  def index
    authorize SystemConfiguration 
  end

  # GET /system_configurations/1/show
  def show
    authorize @system_configuration
  end

  # GET /system_configurations/1/edit
  def edit
    authorize @system_configuration
  end

  # PATCH/PUT /system_configurations/1
  def update
    authorize @system_configuration
    if @system_configuration.update(system_configuration_params)
      redirect_to system_configuration_path(@system_configuration), notice: 'System configuration was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_sys_config
    @system_configuration = SystemConfiguration.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def system_configuration_params
    params.fetch(:sytem_configuration, {}).permit(:value)
  end
end
