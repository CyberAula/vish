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

    #course Management
    can :courses, User

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

    #ServiceRequests
    can :create, ServiceRequest do |request|
      !subject.nil?
    end

    #Download
    can :download_source, ActivityObject do |ao|
      ao.downloadable? or can?(:update, ao.object)
    end

    can :download_source, [Document, Webapp, Scormfile, Imscpfile, Link, Embed, Writing, Excursion, Workshop] do |o|
      can?(:download_source,o.activity_object)
    end


    unless subject.nil?

      #Contributions
      can :create, Contribution do |contribution|
        unless contribution.activity_object.nil?
          can?(:update, contribution.activity_object.object)
        else
          true
        end
      end

      #Comments
      can :comment, ActivityObject do |ao|
        ao.commentable?
      end

      can :comment, [Document, Webapp, Scormfile, Imscpfile, Link, Embed, Writing, Excursion, Workshop] do |o|
        can?(:comment,o.activity_object)
      end

      #Analytics
      can :show_analytics, [Document, Webapp, Scormfile, Imscpfile, Link, Embed, Writing, Excursion, Workshop] do |o|
        can?(:update,o)
      end

      #Clone
      can :clone, ActivityObject do |ao|
        ao.clonable? or can?(:update, ao.object)
      end

      can :clone, [Excursion] do |o|
        can?(:clone,o.activity_object)
      end

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

      can :manage, ServicePermission do |sp|
        subject.admin? and can?(:edit_roles,sp.owner)
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

      #Allow teachers to see resources of their private students
      can :show, ActivityObject do |ao|
        ao.public_scope? or (!ao.owner.nil? and ao.owner.object_type=="Actor" and ao.owner.subject_type=="User" and ao.owner.role?("PrivateStudent") and !ao.owner.user.private_teacher.nil? and ao.owner.user.private_teacher.id==subject.actor_id)
      end

      can :show, [Document, Webapp, Scormfile, Imscpfile, Link, Embed, Writing, Excursion, Workshop, Course] do |o|
        can?(:show,o.activity_object)
      end

      #Allow teachers to edit excursions (i.e. see them in the VE) of their private students
      can [:edit,:update], Excursion do |e|
        !e.owner.nil? and e.owner.role?("PrivateStudent") and !e.owner.user.private_teacher.nil? and e.owner.user.private_teacher.id==subject.actor_id
      end

    end


    #Helpers
    can :show, Array do |arr|
      arr.all? { |el| can?(:show, el) }
    end
    can :edit, Array do |arr|
      arr.all? { |el| can?(:edit, el) }
    end
    can :update, Array do |arr|
      arr.all? { |el| can?(:update, el) }
    end

  end
end
