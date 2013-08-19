DocumentsController.class_eval do

  def allowed_params
    [:file, :language, :age_min, :age_max]
  end
  
end
