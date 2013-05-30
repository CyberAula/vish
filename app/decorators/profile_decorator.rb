Profile.class_eval do
  has_one 	:user, 
  			:through => :actor,
  			:autosave   => true

  delegate :occupation_t, :occupation?,:occupation, :occupation=,
           to: :user

end
