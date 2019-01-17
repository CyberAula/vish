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
    user = find_by_email(auth.info.email)
    if user
      return user
    else
      #EIDAS Case
      #does not exist in BBDD, create it
      u = User.new(provider: auth.provider, uid: auth.uid)
      u.email = auth.info.email
      u.password = Devise.friendly_token[0,20]
      if auth.info.name
        u.name = auth.info.name
      elsif auth.extra && auth.extra.raw_info && auth.extra.raw_info.eidas_profile && auth.extra.raw_info.eidas_profile.FirstName
        u.name = auth.extra.raw_info.eidas_profile.FirstName + " " + auth.extra.raw_info.eidas_profile.FamilyName
      elsif auth.extra && auth.extra.raw_info && auth.extra.raw_info.username
        u.name = auth.extra.raw_info.username
      else
        u.name = auth.info.name
      end

      u.save!

      if auth.extra && auth.extra.raw_info && auth.extra.raw_info.eidas_profile && auth.extra.raw_info.eidas_profile.DateOfBirth
        u.birthday = Date.parse(auth.extra.raw_info.eidas_profile.DateOfBirth)
      end
      u.tag_list = [ "ETSIT" ]
      if auth.extra && auth.extra.raw_info && auth.extra.raw_info.organizations
        u.organization = auth.extra.raw_info.organizations
      end
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
