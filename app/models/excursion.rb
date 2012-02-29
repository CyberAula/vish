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

  private

  def parse_for_meta
    parsed_json = ActiveSupport::JSON.decode(json)
    activity_object.title = parsed_json["name"]
    activity_object.description = parsed_json["description"]
    activity_object.save!
  end

end
