class DatasetsController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_owner, only: %i[ show edit new create update destroy test_ticket ]
  before_action :set_dataset, only: %i[ show edit update destroy ]

  # GET /datasets
  def index
    @datasets = policy_scope(Dataset).all
  end

  # GET /datasets/1
  def show
    authorize @dataset
  end

  # GET /datasets/new
  def new
    authorize Dataset
    @dataset = @owner.datasets.build
  end

  # GET /datasets/1/edit
  def edit
    authorize @dataset
  end

  # POST /datasets
  def create
    @dataset = @owner.datasets.new(dataset_params)
    authorize @dataset

    if @dataset.save
      redirect_to [@owner, @dataset], notice: "Dataset was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /datasets/1
  def update
    authorize @dataset
    if @dataset.update(dataset_params)
      redirect_to [@owner, @dataset], notice: "Dataset was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /datasets/1
  def destroy
    authorize @dataset
    @dataset.destroy!
    redirect_to owner_url(@owner), notice: "Dataset was successfully destroyed.", status: :see_other
  end

  def test_ticket
    @dataset = @owner.datasets.find(params[:dataset_id])
    authorize @dataset
    if request.post?
      @ticket = Ticket.new(params.fetch(:ticket, {}).permit(:geom))
      @ticket.init_test_ticket
      if @ticket.save
        redirect_to [@owner, @dataset], notice: "Test ticket created.", status: :see_other
      else
        render :test_ticket, status: :unprocessable_entity
      end
    else
      @ticket = Ticket.new
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_dataset
      @dataset = @owner.datasets.find(params[:id])
    end

    def set_owner
      @owner = policy_scope(Owner).find(params[:owner_id])
    end

    # Only allow a list of trusted parameters through.
    def dataset_params
      params.fetch(:dataset, {}).permit(:owner_id,
                                        :source_dataset,
                                        :geometry_name,
                                        :layer_name,
                                        :source_sql,
                                        :name,
                                        :source_co,
                                        :source_srs,
                                        :cache_whole_dataset,
                                        :enabled)
    end
end
