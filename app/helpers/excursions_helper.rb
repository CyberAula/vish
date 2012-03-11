module ExcursionsHelper
  def thumb_for(excursion, size)
    image_tag excursion.thumb(size, self)
  end

  def num_slides(excursion)
    excursion.slide_count.to_s
  end
end
