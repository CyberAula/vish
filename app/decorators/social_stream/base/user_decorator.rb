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

  Occupation = [:select, :teacher, :scientist, :other]

  scope :registered, lambda {
    User.where("invited_by_id IS NULL or invitation_accepted_at is NOT NULL")
  }

  before_validation :fill_user_locale

  if Vish::Application.config.cas
    validates :password, :presence =>true,  :confirmation =>true, length: { minimum: Devise.password_length.min, maximum: Devise.password_length.max }, :on=>:create
  end

  devise :omniauthable, omniauth_providers: %i[idm]

  validate :user_locale
  def user_locale
    if !self.language.blank? and I18n.available_locales.include?(self.language.to_sym)
      true
    else
      errors[:base] << "User without language"
    end
  end

  belongs_to :private_student_group
  has_one :private_teacher, class_name: "Actor", through: :private_student_group
  has_and_belongs_to_many :courses

  before_destroy :destroy_user_resources


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

  def has_permission(perm_key)
    ServicePermission.where(:owner_id => actor_id, :key => perm_key).count > 0
  end

  def self.from_omniauth(auth)
    #get user email
    if auth["extra"] && auth["extra"]["raw_info"] && auth["extra"]["raw_info"]["eidas_profile"] && auth["extra"]["raw_info"]["eidas_profile"]["Email"]
      email = auth["extra"]["raw_info"]["eidas_profile"]["Email"].downcase
    elsif auth["extra"] && auth["extra"]["raw_info"] && auth["extra"]["raw_info"]["email"]
      email = auth["extra"]["raw_info"]["email"].downcase
    else
      email = auth["info"]["email"].downcase
    end
    user = find_by_email(email)
    if user
      return user
    else
      #OAuth Case. User does not exist in BBDD, create it.
      u = User.new(provider: auth.provider, uid: auth.uid)
      u.email = email
      u.password = Devise.friendly_token[0,20]
      u.provider = "idm"
      if auth["info"] && auth["info"]["name"]
        u.name = auth["info"]["name"]
      elsif auth["extra"] && auth["extra"]["raw_info"] && auth["extra"]["raw_info"]["eidas_profile"] && auth["extra"]["raw_info"]["eidas_profile"]["FirstName"]
        u.name = auth["extra"]["raw_info"]["eidas_profile"]["FirstName"] + " " + auth["extra"]["raw_info"]["eidas_profile"]["FamilyName"]
      elsif auth["extra"] && auth["extra"]["raw_info"] && auth["extra"]["raw_info"]["username"]
        u.name = auth["extra"]["raw_info"]["username"]
      else
        u.name = auth["info"]["name"]
      end
      u.save!

      if auth["extra"] && auth["extra"]["raw_info"] && auth["extra"]["raw_info"]["eidas_profile"]
        #EIDAS
        #birthday
        if auth["extra"]["raw_info"]["eidas_profile"]["DateOfBirth"]
          u.birthday = Date.parse(auth["extra"]["raw_info"]["eidas_profile"]["DateOfBirth"])
        end
        #city
        if auth["extra"]["raw_info"]["eidas_profile"]["PlaceOfBirth"]
          u.city = auth["extra"]["raw_info"]["eidas_profile"]["PlaceOfBirth"]
        end
        #country
        if auth["extra"]["raw_info"]["eidas_profile"]["CountryOfBirth"]
          u.country = Eid4u.getCountry(auth["extra"]["raw_info"]["eidas_profile"]["CountryOfBirth"])
        end
        #language
        if auth["extra"]["raw_info"]["eidas_profile"]["CountryOfBirth"] && auth["extra"]["raw_info"]["eidas_profile"]["CountryOfBirth"] == "ES"
          u.language = "es"
        else
          u.language = "en"
        end
        #organization
        if auth["extra"]["raw_info"]["eidas_profile"]["HomeInstitutionName"]
          u.organization = auth["extra"]["raw_info"]["eidas_profile"]["HomeInstitutionName"]
        elsif auth["extra"] && auth["extra"]["raw_info"] && auth["extra"]["raw_info"]["organizations"]
          u.organization = auth["extra"]["raw_info"]["organizations"].join(" ")
        end
        #tags
        user_tags = nil
        user_tags = Eid4u.getTagsFromIscedCode(auth["extra"]["raw_info"]["eidas_profile"]["FieldOfStudy"]) unless auth["extra"]["raw_info"]["eidas_profile"]["FieldOfStudy"].blank?
        if user_tags.is_a? String
          u.tag_list = user_tags.split(' ')
        else
          u.tag_list = [ "Erasmus" ]
        end
      end

      u.save!

      return u
    end
  end

  private

  def fill_user_locale
    self.language = I18n.default_locale.to_s unless (!self.language.blank? and I18n.available_locales.include?(self.language.to_sym))
  end

  def destroy_user_resources
    ActivityObject.authored_by(self).each do |ao|
      object = ao.object
      object.destroy unless object.nil?
    end

    ActivityObject.owned_by(self).each do |ao|
      object = ao.object
      object.destroy unless object.nil?
    end
  end

end
