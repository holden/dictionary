class PasswordsController < ApplicationController
  skip_before_action :authenticate, only: [:new, :create, :edit, :update]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordMailer.with(user: user).reset.deliver_later
      redirect_to root_path, notice: "Check your email for reset instructions"
    else
      redirect_to new_password_path, alert: "Email address not found"
    end
  end

  def edit
    @user = User.find_signed!(params[:token], purpose: :password_reset)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: "That password reset link is invalid"
  end

  def update
    @user = User.find_signed!(params[:token], purpose: :password_reset)
    if @user.update(password_params)
      redirect_to new_session_path, notice: "Your password has been reset successfully. Please sign in"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def password_params
      params.require(:password).permit(:password, :password_confirmation)
    end
end
