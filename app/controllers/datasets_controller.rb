class DatasetsController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_owner, only: %i[show edit new create new_wizard create_step1 create_step2 create_step3 update
                                     destroy test_ticket verify_metadata]
  before_action :set_dataset, only: %i[show edit update destroy verify_metadata]
  before_action :verify_credential_id, only: %i[edit update create create_step1 create_step2 create_step3]


  # GET /datasets/1
  def show
    authorize @dataset
  end

  # GET /datasets/new
  def new
    authorize Dataset
    @dataset = @owner.datasets.build
  end

  def create
    @dataset = @owner.datasets.new(dataset_params)
    authorize @dataset
    if @dataset.save(context: :basic)
      redirect_to [@owner, @dataset], notice: t('datasets.create.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /datasets/1/edit
  def edit
    authorize @dataset
  end

  def new_wizard
    authorize Dataset
    @dataset = @owner.datasets.build
    @layers = []
    @options = []
    @url = create_step1_owner_dataset_path(id: @owner)
    render :step1
  end

  def create_step1
    @dataset = @owner.datasets.new(dataset_params)
    authorize @dataset
    @layers = []
    @options = []
    if @dataset.name.blank? || @dataset.source_dataset.blank?
      @dataset.valid?
      @url = create_step1_owner_dataset_path(id: @owner)
      render :step1, status: :unprocessable_entity
    else
      get_metadata
      if @layers.size > 1
        @url = create_step2_owner_dataset_path(id: @owner)
        render :step2
      else
        @url = create_step3_owner_dataset_path(@owner)
        render :step3
      end
    end
  rescue StandardError => e
    @url = create_step1_owner_dataset_path(id: @owner)
    @dataset.source_error = e.message
    flash[:error] = t('datasets.error', message: e.message)
    render :step1, status: :unprocessable_entity
  end

  def create_step2
    @dataset = @owner.datasets.new(dataset_params)
    authorize @dataset
    @layers = []
    @options = []
    get_metadata
    if @dataset.layer_name.blank?
      @dataset.valid?
      @url = create_step2_owner_dataset_path(id: @owner)
      render :step2, status: :unprocessable_entity
    else
      @url = create_step3_owner_dataset_path(@owner)
      render :step3
    end
  rescue StandardError => e
    @dataset.source_error = e.message
    flash[:error] = t('datasets.error', message: e.message)
    render :step2, status: :unprocessable_entity
  end

  def create_step3
    @dataset = @owner.datasets.new(dataset_params)
    authorize @dataset
    @url = create_step3_owner_dataset_path(@owner)
    get_metadata
    if @dataset.source_dataset.present? &&
       @dataset.layer_name.present? &&
       @dataset.save
      redirect_to [@owner, @dataset], notice: t('datasets.create.success')
    else
      render :step3, status: :unprocessable_entity
    end
  rescue StandardError => e
    @dataset.source_error = e.message
    flash[:error] = t('datasets.error', message: e.message)
    render :step3, status: :unprocessable_entity
  end

  def get_metadata
    @layers, @geomFields, @options = @dataset.get_metadata
    if @layers.size == 0
      raise t('datasets.metadata.no_layers')
    elsif @layers.size == 1
      @dataset.layer_name = @layers.first
    end

    return unless @geomFields.size == 1

    @dataset.geometry_name = @geomFields.first
  end

  # PATCH/PUT /datasets/1
  def update
    authorize @dataset
    if @dataset.update(dataset_params)
      redirect_to [@owner, @dataset], notice: t('datasets.update.success'), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /datasets/1
  def destroy
    authorize @dataset
    @dataset.destroy!
    redirect_to owner_url(@owner), notice: t('datasets.destroy.success'), status: :see_other
  end

  def test_ticket
    @dataset = @owner.datasets.find(params[:dataset_id])
    authorize @dataset
    if request.post?
      @ticket = @dataset.test_tickets.build(params.fetch(:ticket, {}).permit(:geom))
      @ticket.init_test_ticket
      if @ticket.save
        redirect_to [@owner, @dataset], notice: t('datasets.test_ticket.success'), status: :see_other
      else
        render :test_ticket, status: :unprocessable_entity
      end
    else
      @ticket = @dataset.test_tickets.build
    end
  end

  # POST /owners/1/datasets/1/verify_metadata
  def verify_metadata
    authorize @dataset
    begin
      @dataset.get_metadata
      flash[:notice] = t('datasets.verify_metadata.success')
    rescue StandardError => e
      flash[:error] = t('datasets.verify_metadata.error', message: e.message)
    end
    redirect_to [@owner, @dataset]
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dataset
    @dataset = @owner.datasets.find(params[:id])
  end

  def set_owner
    @owner = policy_scope(Owner).find(params[:owner_id])
  end

  # Verify the credential id is one that is accessible by the owner
  def verify_credential_id
    return unless dataset_params[:credential_id].present?

    credential_id = dataset_params[:credential_id]
    raise Pundit::NotAuthorizedError unless @owner.service_authentication_configurations.find_by(id: credential_id)
  end

  # Only allow a list of trusted parameters through.
  def dataset_params
    params.fetch(:dataset, {}).permit(:owner_id,
                                      :provider_fid,
                                      :owner_fid,
                                      :source_dataset,
                                      :layer_name,
                                      :geometry_name,
                                      :layer_name,
                                      :feature_class,
                                      :status,
                                      :size,
                                      :depth,
                                      :accuracy_class,
                                      :description,
                                      :source_sql,
                                      :name,
                                      :source_srs,
                                      :cache_whole_dataset,
                                      :enabled,
                                      :source_co_v,
                                      :order_by,
                                      :credential_id)
  end
end
