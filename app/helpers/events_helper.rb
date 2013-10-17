module EventsHelper
  
  def event_raw_thumbail(event)
    !event.poster.id.nil? ? event.poster.file.url : "/assets/items/rec2.jpg"
  end

end