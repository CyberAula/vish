# encoding: utf-8
require 'json'

class VishEditor
  
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

      if elBody.include?("http://docs.google.com")
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

end