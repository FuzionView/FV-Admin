class FeatureStatusesController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_feature_status, only: %i[edit update destroy]

  # GET /feature_statuses
  def index
    authorize FeatureStatus
    @feature_statuses = FeatureStatus.all
  end

  # GET /feature_statuses/new
  def new
    authorize FeatureStatus
    @feature_status = FeatureStatus.new
  end

  # GET /feature_statuses/1/edit
  def edit
    authorize @feature_status
  end

  # POST /feature_statuses
  def create
    authorize FeatureStatus
    @feature_status = FeatureStatus.new(feature_status_params)

    if @feature_status.save
      redirect_to feature_statuses_path, notice: t("feature_statuses.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /feature_statuses/1
  def update
    authorize @feature_status
    if @feature_status.update(feature_status_params)
      redirect_to feature_statuses_path, notice: t("feature_statuses.update.success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /feature_statuses/1
  def destroy
    authorize @feature_status
    @feature_status.destroy!
    redirect_to feature_statuses_url, notice: t("feature_statuses.destroy.success"), status: :see_other
  rescue ActiveRecord::InvalidForeignKey => _e
    redirect_to(feature_statuses_url, notice: t("feature_statuses.destroy.foreign_key_error"),
                                      status: :see_other)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_feature_status
    @feature_status = FeatureStatus.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def feature_status_params
    params.fetch(:feature_status, {}).permit(:id, :name)
  end
end
