class HomeController < ApplicationController
  before_filter :authenticate_user!

  def index
# FIXME
#    @activities_net = current_subject.wall(:home).page(params[:page_net])
#    @activities_me = current_subject.wall(:profile, :for => current_subject).page(params[:page_me])
    if (current_subject.tag_list.count == 0 || !current_subject.profile.occupation?) && rand(2)==1 #half of the times
      flash[:notice] = I18n.t("notice.fill_profile",:url => user_profile_url(current_subject)).html_safe
    end
    respond_to do |format|
      format.js
      format.html
      format.json { render json: home_json }
    end
  end

  private

  def home_json
    {
      name: current_subject.name
    }.to_json
  end
end
