class OwnersController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_owner, only: %i[show edit update destroy service_area delete_service_area]

  # GET /owners
  def index
    authorize Owner
    @owners = policy_scope(Owner.order(:name))
  end

  # GET /owners/1
  def show
    authorize @owner
  end

  # GET /owners/new
  def new
    authorize Owner
    @owner = Owner.new
  end

  # GET /owners/1/edit
  def edit
    authorize @owner
  end

  # POST /owners
  def create
    authorize Owner
    @owner = Owner.new(owner_params)

    if @owner.save
      redirect_to @owner, notice: t('owners.create.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /owners/1
  def update
    authorize @owner
    if @owner.update(owner_params)
      redirect_to @owner, notice: t('owners.update.success'), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /owners/1
  def destroy
    authorize @owner
    @owner.destroy!
    redirect_to owners_url, notice: t('owners.destroy.success'), status: :see_other
  end

  def service_area
    authorize @owner
    return unless request.post?

    @owner.service_area = params[:owner][:service_area]
    if @owner.save
      redirect_to service_area_owner_path(owner_id: @owner), notice: t('owners.service_area.success'),
                                                             status: :see_other
    else
      render :service_area, status: :unprocessable_entity
    end
  end

  def delete_service_area
    authorize @owner
    return unless request.post?

    if @owner.update_column(:service_area, nil)
      redirect_to service_area_owner_path(owner_id: @owner), notice: t('owners.service_area.delete_success'),
                                                             status: :see_other
    else
      render :service_area, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_owner
    @owner = policy_scope(Owner).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def owner_params
    params.fetch(:owner, {}).permit(:name)
  end
end
