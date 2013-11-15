UsersController.class_eval do

  def resources
    respond_to do |format|
      format.js
    end
  end
end
