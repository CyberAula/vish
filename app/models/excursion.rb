class Excursion < ActiveRecord::Base
  include SocialStream::Models::Object

  validates_presence_of :json
  before_save :parse_for_meta

  define_index do
    indexes activity_object.title
    indexes activity_object.description
    has created_at
  end

  def to_json
    json
  end

  def thumb(size, helper)
    case size
      when 50 
        "logos/actor/excursion-#{sprintf '%.2i', thumbnail_index}.png"
      else
        "logos/original/excursion-#{sprintf '%.2i', thumbnail_index}.png"
    end
  end

  private

  def parse_for_meta
    parsed_json = JSON(json)
    activity_object.title = parsed_json["title"]
    activity_object.description = parsed_json["description"]
    activity_object.save!

    self.slide_count = parsed_json["slides"].size
  end

end
