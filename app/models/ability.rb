class Ability
  include SocialStream::Ability

  def initialize(subject)
    
    if !subject.nil? and subject.is_admin
      can :manage, :all
    end

    can [:create, :update], WorkshopActivity do |wa|
      wa.workshop.nil? || can?(:update, wa.workshop)
    end

    can [:create, :update], [WaAssignment,WaContributionsGallery,WaResource,WaResourcesGallery,WaText] do |waObject|
      can?(:update, waObject.workshop_activity)
    end

    can :show_favorites, Category
    can :excursions, User
    can :workshops, User
    can :resources, User
    can :events, User
    can :categories, User
    can :followers, User
    can :followings, User

    super
  end
end
