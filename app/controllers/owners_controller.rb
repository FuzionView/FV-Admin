class OwnersController < ApplicationController
  before_action :set_owner, only: %i[ show edit update destroy ]

  # GET /owners
  def index
    @owners = Owner.all
  end

  # GET /owners/1
  def show
  end

  # GET /owners/new
  def new
    @owner = Owner.new
  end

  # GET /owners/1/edit
  def edit
  end

  # POST /owners
  def create
    @owner = Owner.new(owner_params)

    if @owner.save
      redirect_to @owner, notice: "Owner was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /owners/1
  def update
    if @owner.update(owner_params)
      redirect_to @owner, notice: "Owner was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /owners/1
  def destroy
    @owner.destroy!
    redirect_to owners_url, notice: "Owner was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_owner
      @owner = Owner.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def owner_params
      params.fetch(:owner, {}).permit(:name)
    end
end
