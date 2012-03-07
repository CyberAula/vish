class Excursion < ActiveRecord::Base
  include SocialStream::Models::Object

  validates_presence_of :json
  # before_save :parse_for_meta ## TODO: Wait until we define the excursion JSON schema

  define_index do
    indexes activity_object.title
    indexes activity_object.description
    has created_at
  end

  def to_json
    json
  end

  def thumb(size, helper)
    "excursion.png"
  end

  private

  def parse_for_meta
    parsed_json = JSON(json)
    activity_object.title = parsed_json["name"]
    activity_object.description = parsed_json["description"]
    activity_object.save!
  end

end
