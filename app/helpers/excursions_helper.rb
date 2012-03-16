module ExcursionsHelper
  def thumb_for(excursion, size)
    image_tag excursion.thumb(size, self)
  end

  def num_slides(excursion)
    excursion.slide_count.to_s
  end

  def num_followers
    # TODO: really take the top 10 excursions
    rand(500)
  end

  def type_excursion
    # TODO: really take the top 10 excursions
    value=1

    if (value==1)
      "virtual meeting"
    else
      "presentation"
    end
  end

  def starts
    # TODO: really take the top 10 excursions
    value=1 + (10)
  end

end
