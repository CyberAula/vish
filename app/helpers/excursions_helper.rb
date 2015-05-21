module ExcursionsHelper
  
  def excursion_thumb_for(excursion,size=nil)
    return image_tag("/assets/icons/draft.jpg") if excursion.draft
    image_tag (excursion.thumbnail_url || "/assets/logos/original/excursion-00.png")
  end

  def excursion_raw_thumbail(excursion)
    excursion.thumbnail_url || "/assets/logos/original/excursion-00.png"
  end

end
