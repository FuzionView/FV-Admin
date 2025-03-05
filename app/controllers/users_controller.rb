class UsersController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized
  before_action :set_owner, only: %i[ index edit new create update destroy ]
  before_action :set_user, only: %i[ edit update destroy ]

  # GET /users
  def index
    authorize User
    @users =  policy_scope(User).all
  end

  # GET /users/new
  def new
    authorize User
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    authorize @user
  end

  # POST /users
  def create
    authorize User
    @user = @owner.users.build(user_params)

    if @user.save
      redirect_to owner_users_path(@owner), notice: t('users.create.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /users/1
  def update
    authorize @user
    if @user.update(user_params)
      redirect_to owner_users_path(@owner), notice: t('users.update.success'), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /users/1
  def destroy
    authorize @user
    @user.destroy!
    redirect_to owner_users_path(@owner), notice: t('users.destroy.success'), status: :see_other
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = @owner.users.find(params[:id])
  end

  def set_owner
    @owner = policy_scope(Owner).find(params[:owner_id])
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:email_address)
  end
end
