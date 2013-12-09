DocumentsController.class_eval do

  def allowed_params
    [:file, :language, :age_min, :age_max, :tag_list=>[]]
  end
  
  def create
    super do |format|
      format.json { render :json => resource.to_json(helper: self), status: :created }
      format.js
      format.all {
        if resource.new_record?
          render action: :new
        else          
          redirect_to resource
        end
      }
    end
  end

  def destroy
    super do |format|
      format.html {
        redirect_to current_user
      }

      format.js
    end
  end

end
