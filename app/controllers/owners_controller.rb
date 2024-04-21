class OwnersController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_owner, only: %i[ show edit update destroy ]

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
      redirect_to @owner, notice: "Data provider was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /owners/1
  def update
    authorize @owner
    if @owner.update(owner_params)
      redirect_to @owner, notice: "Data provider was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /owners/1
  def destroy
    authorize @owner
    @owner.destroy!
    redirect_to owners_url, notice: "Data provider was successfully destroyed.", status: :see_other
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
