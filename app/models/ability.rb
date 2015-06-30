class Ability
  include SocialStream::Ability

  def initialize(subject)
    
    if !subject.nil? and subject.admin?
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
      can?(:update, waObject.workshop_activity) and can?(:update, waObject.wa_assignments)
    end

    unless subject.nil?
      can :create, Contribution do |contribution|
        unless contribution.activity_object.nil?
          can?(:update, contribution.activity_object.object)
        else
          true
        end
      end
    end

    #Helpers
    can :update, Array do |arr|
      arr.all? { |el| can?(:update, el) }
    end

    super
  end
end
