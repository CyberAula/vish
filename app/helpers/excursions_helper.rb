# encoding: utf-8

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
    #Some metadata are in the json in the fields:
    #language context age-range difficulty TLT subject educational_objectives

    if !excursion.title.nil?
      metadata["Title"] = excursion.title
    end

    if !excursion.description.nil?
      metadata["Description"] = excursion.description
    end

    if !excursion.tag_list.nil? and excursion.tag_list.is_a? Array 
      metadata["Keywords"] = excursion.tag_list.join(", ")
    end

    if parsed_json["language"] != "independent"
      metadata["Language"] = readable_language(parsed_json["language"])
    end
    if parsed_json["context"] 
      metadata["Context"] = parsed_json["context"]
    end
    if parsed_json["age_range"] 
      metadata["Age Range"] = parsed_json["age_range"]
    end
    if parsed_json["difficulty"] 
      metadata["Difficulty"] = parsed_json["difficulty"]
    end
    if parsed_json["TLT"] 
      metadata["Tipical Learning Time"] = parsed_json["TLT"][2..-1] #remove the PT in the beginning
    end
    if parsed_json["subject"] 
      metadata["Subjects"] = parsed_json["subject"].inspect[1..-2] #remove the first and last characters that are "[" and "]"
    end
    if parsed_json["educational_objectives"] 
      metadata["Educational objectives"] = parsed_json["educational_objectives"]
    end
    return metadata
  end

  def readable_language(lanCode)
    case lanCode
      when 'de';
        'Deutsch'
      when 'en';
        'English'
      when 'es';
        'Español'
      when 'fr';
        'Français'
      when 'it';
        'Italiano'
      when 'pt';
        'Português'
      when 'ru';
        'Русский'
      else
        lanCode
    end
  end

end
