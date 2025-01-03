class SessionsController < ApplicationController
  skip_before_action :authenticate, only: [:new, :create]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])&.authenticate(params[:password])
      login(user)
      redirect_to root_path, notice: "Signed in successfully"
    else
      redirect_to new_session_path, alert: "Invalid email or password"
    end
  end

  def destroy
    logout
    redirect_to new_session_path, notice: "Signed out successfully"
  end
end
