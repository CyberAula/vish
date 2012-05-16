module ExcursionsHelper
  def thumb_for(excursion, size)
    image_tag excursion.thumbnail_url
  end

  def num_slides(excursion)
    excursion.slide_count.to_s
  end

  def starts
    # TODO: really take the top 10 excursions
    value=1 + (10)
  end

end
