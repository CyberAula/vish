class Ability
  include SocialStream::Ability

  def initialize(subject)
    # if subject.admin?
    #   can :manage, Object
    # end

    super
  end
end
