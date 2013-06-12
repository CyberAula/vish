class FrontpageController < ApplicationController
  before_filter :redirect_user_to_home, :only => [ :index, :explore ]

  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def explore
    render :layout => 'application'
  end

  def offline
    render :layout => false
  end

  def manifest
    render 'cache.manifest', :layout => false, :content_type => 'text/cache-manifest'
  end

  private

  def redirect_user_to_home
    redirect_to(home_path) if user_signed_in?
  end

end

