module ExcursionsHelper
  def thumb_for(excursion, size)
    image_tag excursion.thumb(size)
  end
end
