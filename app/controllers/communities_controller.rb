
class CommunitiesController < ApplicationController
  before_filter :find_community, only: [:show]
  before_filter :new_invitations_flash
  def index
    @community_users = @user.community_users.paginate(page: params[:page], per_page: 10)
    @invitations = current_user.invitations.paginate(page: params[:invitation_page], per_page: 10)
  end

  def create
    @community = Community.new community_params
    @community.community_users.build role: 'admin', user: @user
    if @community.save
      flash[:notice] = t('communities.new.created')
      redirect_to communities_path
    else
      flash[:error] = t('communities.new.not_created')
      render action: 'new'
    end
  end

  def show
    @invitations = @community.invitations.paginate(page: params[:invitation_page], per_page: 10)
    @community_users = @community.community_users.paginate(page: params[:page], per_page: 20)
  end

  def new
    @community = Community.new
  end

  private
    def new_invitations_flash
      flash[:info] = t('messages.new_invitation') if current_user.invitations.any?
    end

    def community_params
      {creator: @user}.merge params.require(:community).permit(:name, :subdomain, :invitation_emails)
    end



end
