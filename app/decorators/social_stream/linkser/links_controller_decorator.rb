LinksController.class_eval do

  def allowed_params
    [:url, :image, :callback, :width, :height, :callback_url, :loaded, :language, :age_min, :age_max, :tag_list=>[]]
  end
  
end
