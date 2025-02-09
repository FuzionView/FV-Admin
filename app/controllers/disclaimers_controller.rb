class DisclaimersController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_disclaimer, only: %i[show edit update]

  # GET /disclaimers/1/show
  def show
    authorize @disclaimer
  end

  # GET /disclaimers/1/edit
  def edit
    authorize @disclaimer
  end

  # PATCH/PUT /disclaimers/1
  def update
    authorize @disclaimer
    if @disclaimer.update(disclaimer_params)
      redirect_to disclaimer_path(@disclaimer), notice: 'Disclaimer was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_disclaimer
    @disclaimer = Disclaimer.find(Disclaimer.default.id)
  end

  # Only allow a list of trusted parameters through.
  def disclaimer_params
    params.fetch(:disclaimer, {}).permit(:disclaimer_text, :remote_url)
  end
end
