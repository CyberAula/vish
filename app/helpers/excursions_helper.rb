module ExcursionsHelper
  def thumb_for(excursion, size)
    if excursion.is_a? Excursion
      image_tag excursion.thumbnail_url
    else
      image_tag excursion.thumb(size, self)
  end

  def num_slides(excursion)
    excursion.slide_count.to_s
  end

  def starts
    # TODO: really take the top 10 excursions
    value=1 + (10)
  end

end
