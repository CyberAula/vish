module ExcursionsHelper
  def excursion_thumb_for(excursion, size)
    excursion_thumb_for(excursion)
  end

  def excursion_thumb_for(excursion)
    return image_tag("/assets/icons/draft.jpg") if excursion.draft
    image_tag (excursion.thumbnail_url || "/assets/logos/original/excursion-00.png")
  end

  def excursion_raw_thumbail(excursion)
    #return "/assets/icons/draft.jpg" if excursion.draft
    excursion.thumbnail_url || "/assets/logos/original/excursion-00.png"
  end

  def num_slides(excursion)
    excursion.slide_count.to_s
  end

  def starts
    # TODO: really take the top 10 excursions
    value=1 + (10)
  end

  def metadata(excursion)
    parsed_json = JSON(excursion.json)
    metadata = {}
    #metadata are in the json in the fields:
    #language context age-range difficulty TLT subject educational_objectives
    if parsed_json["language"] != "independent"
      metadata["Language"] = parsed_json["language"]
    end
    if parsed_json["context"] 
      metadata["Context"] = parsed_json["context"]
    end
    if parsed_json["age-range"] 
      metadata["Age Range"] = parsed_json["age-range"]
    end
    if parsed_json["difficulty"] 
      metadata["Difficulty"] = parsed_json["difficulty"]
    end
    if parsed_json["TLT"] 
      metadata["Tipical Learning Time"] = parsed_json["TLT"]
    end
    if parsed_json["subject"] 
      metadata["Subject"] = parsed_json["subject"].inspect[1..-2] #remove the first and last characters that are "[" and "]"
    end
    if parsed_json["educational_objectives"] 
      metadata["Educational objectives"] = parsed_json["educational_objectives"]
    end
    return metadata
  end


end
