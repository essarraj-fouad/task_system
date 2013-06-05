class Ability
  include CanCan::Ability

  def initialize(user, community_user, object = nil)
    # Define abilities for the passed in user here. For example:
    #
    alias_action :create, :read, :update, :destroy, :to => :crud
    @object = object
    user ||= User.new # guest user (not logged in)
    if user.try(:global_role) == 'admin'
      can :manage, :all
    elsif community_user.try(:admin?)
      can :manage, :all
    elsif community_user.try(:normal?)
      can :read, :all
      if object_creator?
        can :crud, [User, CommunityUser, Task, TaskOccurrence, Payment]
      end
    else

    end

    def object_creator?
      @bject && @object.try(:user) == @user
    end
    #
    # The first argument to `can` is the action you are giving the user 
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. 
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end