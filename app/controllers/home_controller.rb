class HomeController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      params[:page] ||= "1"
      params[:tab] ||= "home"

      format.html{
        if request.xhr?
            #Ajax call
            if params[:tab]=="home"
              if params[:page] == "1"
                render partial: "home"
              else
                homeModels = VishConfig.getHomeModels({:return_instances => true})
                resourcesPopular = Search.search({:n => 16, :order => "ranking DESC", :ao_ids_to_avoid => params[:ids_to_avoid].split(','), :page => params[:page], :models=> homeModels})
                render partial: "home_popular", :locals => {:resources => resourcesPopular, :ids_to_avoid => params[:ids_to_avoid].split(','), :prefix_id=>"home"}, :layout => false
              end
            elsif params[:tab]=="net"
              params[:sort_by] ||= "ranking"
              if params[:page] == "1"
                render :partial => "network", :locals => {:scope => :net, :page=> params[:page], :sort_by=> params[:sort_by], :prefix_id=>"network"}, :layout => false
              else
                render :partial => "network_resources", :locals => {:scope => :net, :page=> params[:page], :sort_by=> params[:sort_by], :prefix_id=>"network"}, :layout => false
              end
            end
        else
          #Non-Ajax call
          render "index"
        end
      }
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