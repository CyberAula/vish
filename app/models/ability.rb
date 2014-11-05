class Ability
  include SocialStream::Ability

  def initialize(subject)
    
    if !subject.nil? and subject.is_admin
      can :manage, :all
    end

    can :show_favorites, Category
    can :excursions, User
    can :resources, User
    can :events, User
    can :categories, User
    can :followers, User
    can :followings, User

    #Workshop Management
    can :workshops, User

    can [:manage], WorkshopActivity do |wa|
      wa.workshop.nil? || can?(:update, wa.workshop)
    end

    can [:manage], [WaAssignment,WaResource,WaResourcesGallery,WaText] do |waObject|
      can?(:update, waObject.workshop_activity)
    end

    can [:manage], [WaContributionsGallery] do |waObject|
      can?(:update, waObject.workshop_activity)
    end

    super
  end
end
