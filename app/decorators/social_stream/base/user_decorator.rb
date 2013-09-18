User.class_eval do
  attr_accessible :tag_list, :occupation, :description, :organization, :city, :country, :birthday

  delegate  :description, :description=,
            :organization, :organization=,
            :city, :city=,
            :country, :country=,
            to: :profile

  delegate_attributes :birthday, :birthday=,
                      :to => :profile
  
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

  def description
    profile.description
  end
end