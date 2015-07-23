class Ability
  include SocialStream::Ability

  def initialize(subject)
    
    can :show_favorites, Category
    can :excursions, User
    can :resources, User
    can :events, User
    can :categories, User
    can :followers, User
    can :followings, User

    #Call SocialStream
    super

    #ViSH Admins
    if !subject.nil? and subject.admin?
      can :manage, :all
    end

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

    #ServiceRequests
    can :create, ServiceRequest do |request|
      !subject.nil?
    end

    unless subject.nil?
      #Roles and user management
      can :update, Actor do |a|
        a.id == subject.actor_id
      end
      cannot :update, Actor do |a|
        a.admin? and subject.actor_id != a.id
      end
      cannot :update, Actor do |a|
        subject.role?("PrivateStudent")
      end
      cannot :update, User do |u|
        cannot?(:update, u.actor)
      end
      cannot :update, Profile do |p|
        cannot?(:update, p.actor)
      end

      can :destroy, Actor do |a|
        a.id == subject.actor_id
      end
      cannot :destroy, Actor do |a|
        a.admin? and subject.actor_id != a.id
      end
      cannot :destroy, Actor do |a|
        subject.role?("PrivateStudent")
      end
      cannot :destroy, User do |u|
        cannot?(:destroy, u.actor)
      end
      cannot :destroy, Profile do |p|
        cannot?(:destroy, p.actor)
      end

      cannot :edit_roles, Actor do |a|
        cannot?(:update, a) or !subject.admin? or a.admin? or subject.actor_id == a.id
      end
      cannot :edit_roles, User do |u|
        cannot?(:edit_roles, u.actor)
      end
      cannot :edit_roles, Profile do |p|
        cannot?(:edit_roles, p.actor)
      end

      #Private Student Groups
      can :create, PrivateStudentGroup do |psg|
        ServicePermission.where(:key => "PrivateStudentGroups", :owner_id => subject.actor_id).length > 0
      end

      can :show, PrivateStudentGroup do |psg|
        psg.owner_id == subject.actor_id
      end

      can :destroy, PrivateStudentGroup do |psg|
        psg.owner_id == subject.actor_id
      end
    end

    #Helpers
    can :update, Array do |arr|
      arr.all? { |el| can?(:update, el) }
    end

  end
end
