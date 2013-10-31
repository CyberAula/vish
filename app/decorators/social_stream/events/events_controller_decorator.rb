EventsController.class_eval do

  def show
    show!
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
      :embed
    ]
  end

end
