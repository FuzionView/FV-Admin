class TicketTypesController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_ticket_type, only: %i[edit update destroy]

  # GET /ticket_types
  def index
    authorize TicketType
    @ticket_types = TicketType.all
  end

  # GET /ticket_types/new
  def new
    authorize TicketType
    @ticket_type = TicketType.new
  end

  # GET /ticket_types/1/edit
  def edit
    authorize @ticket_type
  end

  # POST /ticket_types
  def create
    authorize TicketType
    @ticket_type = TicketType.new(ticket_type_params)

    if @ticket_type.save
      redirect_to ticket_types_path, notice: t("ticket_types.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /ticket_types/1
  def update
    authorize @ticket_type
    if @ticket_type.update(ticket_type_params)
      redirect_to ticket_types_path, notice: t("ticket_types.update.success"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /ticket_types/1
  def destroy
    authorize @ticket_type
    @ticket_type.destroy!
    redirect_to ticket_types_path, notice: t("ticket_types.destroy.success"), status: :see_other
  rescue ActiveRecord::InvalidForeignKey => _e
    redirect_to(ticket_types_path, notice: t("ticket_types.destroy.foreign_key_error"),
                                   status: :see_other)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_ticket_type
    @ticket_type = TicketType.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def ticket_type_params
    params.fetch(:ticket_type, {}).permit(:id, :description, :color_mapserv, :color_hex)
  end
end
