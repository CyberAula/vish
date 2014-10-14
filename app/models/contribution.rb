class Contribution < ActiveRecord::Base
	belongs_to :assignment
 	belongs_to  :parent, :class_name => 'Contribution'
  	has_many 	:children, :class_name => 'Contribution', :foreign_key => 'parent_id'
  	
  	include SocialStream::Models::Object
end
