class Ability
  include SocialStream::Ability

  def initialize(subject)
    # if subject.admin?
    #   can :manage, Object
    # end

    can :show_favorites, Category
    can :resources, User
    can :events, User
    can :categories, User
    can :followers, User
    can :followings, User

    super
  end
end
