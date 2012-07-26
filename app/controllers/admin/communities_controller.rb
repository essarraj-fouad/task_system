class Admin::CommunitiesController < AdminController
  layout 'admin'
  
  def index
    @filter = filter_name
    @communities = Community.paginate page: params[:page], per_page: 25, conditions: apply_filter + find_community

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @community = Community.new
  end

  def create
    @community = Community.new params[:community]

    if @community.save 
      flash[:notice] = t('messages.save_success')
      redirect_to admin_communities_path
    else
      render action: 'edit'
    end
  end

  def edit
    @community = Community.find params[:id]
  end

  def update
    @community = Community.find params[:id]
    if @community.update_attributes params[:community]
      flash[:notice] = t('messages.save_success')
      redirect_to admin_communities_path
    else
      render action: 'edit'
    end
  end

  def destroy
    @community = Community.find params[:id]
    @community.destroy
    flash[:error] = t('messages.delete')
    redirect_to admin_communities_path
  end



end
