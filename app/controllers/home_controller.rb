class HomeController < ApplicationController
  before_filter :authenticate_user!

  def index
# FIXME
#    @activities_net = current_subject.wall(:home).page(params[:page_net])
#    @activities_me = current_subject.wall(:profile, :for => current_subject).page(params[:page_me])

    respond_to :js, :html
  end
end
