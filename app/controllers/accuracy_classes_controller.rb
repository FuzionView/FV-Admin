class AccuracyClassesController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_accuracy_class, only: %i[show edit update destroy]

  # GET /accuracy_classes
  def index
    authorize AccuracyClass
    @accuracy_classes = AccuracyClass.all
  end

  # GET /accuracy_classes/new
  def new
    authorize AccuracyClass
    @accuracy_class = AccuracyClass.new
  end

  # GET /accuracy_classes/1/edit
  def edit
    authorize AccuracyClass
  end

  # POST /accuracy_classes
  def create
    authorize AccuracyClass
    @accuracy_class = AccuracyClass.new(accuracy_class_params)

    if @accuracy_class.save
      redirect_to accuracy_classes_path, notice: 'Accuracy class was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /accuracy_classes/1
  def update
    authorize AccuracyClass
    if @accuracy_class.update(accuracy_class_params)
      redirect_to accuracy_classes_path, notice: 'Accuracy class was successfully updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /accuracy_classes/1
  def destroy
    authorize AccuracyClass
    @accuracy_class.destroy!
    redirect_to accuracy_classes_url, notice: 'Accuracy class was successfully destroyed.', status: :see_other
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_accuracy_class
    @accuracy_class = AccuracyClass.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def accuracy_class_params
    params.fetch(:accuracy_class).permit(:id, :name)
  end
end
