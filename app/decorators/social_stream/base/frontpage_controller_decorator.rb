FrontpageController.class_eval do
  private

  def redirect_user_to_home
    redirect_to(excursions_path) if user_signed_in?
  end
end
