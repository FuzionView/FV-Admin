class DatasetsController < ApplicationController
  before_action :set_dataset, only: %i[ show edit update destroy ]

  # GET /datasets
  def index
    @datasets = Dataset.all
  end

  # GET /datasets/1
  def show
  end

  # GET /datasets/new
  def new
    @owner = Owner.find(params[:owner_id])
    @dataset = @owner.datasets.build
  end

  # GET /datasets/1/edit
  def edit
  end

  # POST /datasets
  def create
    @dataset = Dataset.new(dataset_params)

    if @dataset.save
      redirect_to @dataset, notice: "Dataset was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /datasets/1
  def update
    if @dataset.update(dataset_params)
      redirect_to @dataset, notice: "Dataset was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /datasets/1
  def destroy
    @dataset.destroy!
    redirect_to datasets_url, notice: "Dataset was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dataset
      @dataset = Dataset.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def dataset_params
      params.fetch(:dataset, {}).permit(:owner_id,
                                        :source_dataset,
                                        :source_sql,
                                        :name,
                                        :source_co,
                                        :source_srs,
                                        :cache_whole_dataset,
                                        :enabled)
    end
end
