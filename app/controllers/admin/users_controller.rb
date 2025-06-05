# RPII Utility - Admin controller for user management
class Admin::UsersController < ApplicationController
  before_action :authenticate_admin!

  # Manage RPII inspector accounts
  def index
    @users = User.includes(:inspector_companies).order(:email)
  end

  def show
    @user = User.find(params[:id])
    @inspection_stats = @user.inspection_statistics
  end

  def update_rpii_status
    @user = User.find(params[:id])
    @user.update(rpii_verified: params[:verified])
    redirect_to admin_user_path(@user)
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: 'User updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :rpii_registration_number, :rpii_verified)
  end
end