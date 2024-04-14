class UsersController < ApplicationController
  before_action :set_owner, only: %i[ show edit new create update destroy ]
  before_action :set_user, only: %i[ show edit update destroy ]

  # GET /users
  def index
    @users = User.all
  end

  # GET /users/1
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  def create
    @user = @owner.users.build(user_params)

    if @user.save
      redirect_to owner_path(@owner), notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update(user_params)
      redirect_to owner_path(@owner), notice: "User was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy!
    redirect_to owner_url(@owner), notice: "User was successfully destroyed.", status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = @owner.users.find(params[:id])
    end

    def set_owner
      @owner = Owner.find(params[:owner_id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:email_address)
    end
end
