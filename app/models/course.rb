class Course < ActiveRecord::Base
  include SocialStream::Models::Object
  has_and_belongs_to_many :users

end