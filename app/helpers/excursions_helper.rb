module ExcursionsHelper
  def thumb_for(excursion, size)
    image_tag excursion.thumb(size, self)
  end
end
