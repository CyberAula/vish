ActivitiesController.class_eval do

  before_filter :authenticate_user!, :only => [:index]

  def index
    @activities = Activity.timeline(current_section,current_subject).page(params[:page])

    respond_to do |format|
      format.html {
        if(params.has_key?(:page))
          render @activities
        end
      }
      format.atom
    end
  end

end
