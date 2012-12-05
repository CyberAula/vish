class HomeController < ApplicationController
  before_filter :authenticate_user!

  def index
# FIXME
#    @activities_net = current_subject.wall(:home).page(params[:page_net])
#    @activities_me = current_subject.wall(:profile, :for => current_subject).page(params[:page_me])

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
