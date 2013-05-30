User.class_eval do
  attr_accessible :tag_list, :occupation
  
  Occupation = [:select, :teacher, :scientist, :other]

  def occupation_sym
  	if occupation
  		Occupation[occupation]
  	else
  		:select
  	end
  end

  def occupation_t
  	I18n.t "profile.occupation.options.#{occupation_sym}"
  end

end