class Users::RegistrationsController  < Devise::RegistrationsController

 skip_before_filter :verify_authenticity_token
 
  respond_to :json

  def create

    user = User.new(user_params)

    if user.save
      render :json => user.as_json( :email=>user.email), :status=>201
      return
    else
      warden.custom_failure!
      render :json => user.errors, :status=>422
    end
  end

  def user_params
    params.require(:user).permit(:email, :password)
  end

end