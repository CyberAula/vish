DocumentsController.class_eval do

  def allowed_params
    [:file, :language, :age_min, :age_max, :tag_list=>[]]
  end
  
end
