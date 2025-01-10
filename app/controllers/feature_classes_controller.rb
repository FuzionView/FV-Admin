class FeatureClassesController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_feature_class, only: %i[ edit update destroy ]

  # GET /feature_classes
  def index
    authorize FeatureClass
    @feature_classes = FeatureClass.all
  end

  # GET /feature_classes/new
  def new
    authorize FeatureClass
    @feature_class = FeatureClass.new
  end

  # GET /feature_classes/1/edit
  def edit
    authorize @feature_class
  end

  # POST /feature_classes
  def create
    authorize FeatureClass
    @feature_class = FeatureClass.new(feature_class_params)

    if @feature_class.save
      redirect_to feature_classes_path, notice: "Feature class was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /feature_classes/1
  def update
    authorize @feature_class
    if @feature_class.update(feature_class_params)
      redirect_to feature_classes_path, notice: "Feature class was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /feature_classes/1
  def destroy
    authorize @feature_class
    @feature_class.destroy!
    redirect_to feature_classes_url, notice: "Feature class was successfully destroyed.", status: :see_other
  rescue ActiveRecord::InvalidForeignKey => _e
    redirect_to(feature_classes_url, notice: "Feature class is associated with other records and can't be deleted.",
      status: :see_other)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_feature_class
      @feature_class = FeatureClass.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def feature_class_params
      params.fetch(:feature_class, {}).permit(:id, :name, :color_mapserv, :color_hex, :code)
    end
end
