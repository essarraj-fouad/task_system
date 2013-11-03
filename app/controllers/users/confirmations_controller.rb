class Users::ConfirmationsController < Devise::ConfirmationsController
  def resource_params
    params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
  end
  private :resource_params

end