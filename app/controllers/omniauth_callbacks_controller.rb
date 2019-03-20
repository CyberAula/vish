class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def idm
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: "Facebook") if is_navigational_format?
    else
      session["devise.idm_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def failure
    logger.debug "FAILURE IN OmniauthCallbacksController. Session:"
    logger.debug session.to_s
    logger.debug "params: " + params.to_s
    redirect_to root_path
  end
end
