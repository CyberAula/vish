User.class_eval do
  attr_accessible :tag_list, :occupation, :description, :organization, :city, :country, :birthday, :website

  delegate  :description, :description=,
            :organization, :organization=,
            :city, :city=,
            :country, :country=,
            :website, :website=,
            to: :profile

  delegate_attributes :birthday, :birthday=,
                      :to => :profile

  before_destroy :destroy_user_resources

  belongs_to :private_student_group
  has_one :private_teacher, class_name: "Actor", through: :private_student_group
  
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


  private

  def destroy_user_resources
    #Destroy user resources

    ActivityObject.authored_by(self).each do |ao|
      object = ao.object
      unless object.nil?
        object.destroy
      end
    end
    
    ActivityObject.owned_by(self).each do |ao|
      object = ao.object
      unless object.nil?
        object.destroy
      end
    end
  end
  
end