# encoding: utf-8
require 'json'

class VishEditorUtils
  
  def self.getElementTypes(loJSON)
    types = []
    begin
      slides = loJSON["slides"]
      types = types + slides.map { |s| s["type"] }
      slides.each do |slide|
        els = slide["elements"]
        if !els.nil?
          types = types + els.map {|el| getElType(el)}
        end
      end
      types.uniq!
      types = types.reject { |type| type.nil? }
    rescue => e
      return "Exception: " + e.message
    end
    return types
  end

  def self.getElType(el)
    if el.nil?
      return nil
    end

    elType = el["type"]

    if elType != "object"
      return elType
    else
      #Look in body param
      elBody = el["body"]

      if elBody.nil? or !elBody.is_a? String
        return elType
      end

      if elBody.include?("://docs.google.com")
        return "document"
      end

      if elBody.include?("www.youtube.com")
        return "video"
      end

      if elBody.include?(".swf") and elBody.include?("embed")
        return "flash"
      end

      return "web"
    end
  end

  def self.getResources(loJSON)
    require "uri"
    resources = []

    begin
      slides = loJSON["slides"]
      standardSlides = []
      
      slides.each do |slide|
        case slide["type"]
        when "flashcard"
          resources = resources + URI.extract(slide["background"],/http(s)?/) unless slide["background"].blank?
          standardSlides = standardSlides + (slide["slides"] || [])
        when "VirtualTour"
          unless slide["map_service"] != "Google Maps" or slide["center"].blank? or slide["center"]["lat"].blank? or slide["center"]["lng"].blank?
            resources.push("VirtualTourWithCenterCoordinates" + slide["center"]["lat"] + "&" + slide["center"]["lng"])
          end
          standardSlides = standardSlides + (slide["slides"] || [])
        when "enrichedvideo"
          resources = resources + URI.extract(slide["video"]["source"],/http(s)?/) unless slide["video"].blank? or slide["video"]["source"].blank?
          standardSlides = standardSlides + (slide["slides"] || [])
        when "standard",nil
          #Standard or default
          standardSlides.push(slide)
        when "quiz"
          #Do nothing
        else
          #Do nothing
        end
      end

      slideElements = []
      standardSlides.each do |slide|
        slideElements = slideElements + (slide["elements"] || [])
      end
      
      slideElements.each do |el|
        case el["type"]
        when nil
          #Do nothing
        when "text"
          if !el["body"].blank?
            rawText = Nokogiri::HTML(el["body"]).text rescue ""
            if rawText.length > 150
              #Do not consider small texts for reusing...
              resources.push(rawText.first(300))
            end
          end
        when "image"
          resources.push(el["body"]) unless el["body"].blank?
        when "object","snapshot"
          resources = resources + URI.extract(el["body"],/http(s)?/) unless el["body"].blank?
        when "video","audio"
          resources = resources + URI.extract(el["sources"],/http(s)?/) unless el["sources"].blank?
        when "quiz"
          unless el["quiztype"].blank? or el["question"]["value"].blank? or el["choices"].blank?
            quizResource = el["quiztype"] + el["question"]["value"] + el["choices"].map{|c| c["value"]}.sum
            resources.push(quizResource)
          end
        else
        end
      end
    rescue => e
      return "Exception: " + e.message
    end

    resources.compact.uniq
  end

end