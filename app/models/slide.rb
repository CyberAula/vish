class Slide < ActiveRecord::Base
  include SocialStream::Models::Object

  def to_json
    json
  end
end
