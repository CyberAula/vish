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
          redirect = 
            ( request.referer.present? ?
              ( request.referer =~ /new$/ ?
                resource :
                request.referer ) :
              home_path )

          redirect_to redirect
        end
      }
    end
  end

  def update
    update! do |success, failure|
      failure.html { render :action => :show }
      success.html {
        if params[:controller] == "pictures"
          redirect_to request.referer
        else
          render :action => :show 
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
