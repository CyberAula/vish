class Ability
  include SocialStream::Ability

  def initialize(subject)
    # if subject.admin?
    #   can :manage, Object
    # end

    can :show_favorites, Category

    super
  end
end
