class WaResource < ActiveRecord::Base
	#Polymorphic
	acts_as_wa
	
	include SocialStream::Models::Object
end
