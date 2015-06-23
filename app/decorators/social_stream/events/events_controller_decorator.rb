EventsController.class_eval do

  def show
    super do |format|
      format.full {
        @title = resource.title
        render :layout => 'iframe'
      }
    end
  end
  
  def allowed_params
    [
      :start_at, :end_at, :all_day,
      :frequency,
      # Weekly
      :week_days,
      # Monthly
      :week_day_order, :week_day, :interval,
      :room_id,
      :streaming,
      :embed,
      :language, :license_id, :age_min, :age_max, :scope, :avatar, :tag_list=>[]
    ]
  end

end
