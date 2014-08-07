class HomeController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      params[:page] = params[:page]||"1"
      params[:tab] = params[:tab]||"home"
      format.html{
        if request.xhr?
            #Ajax call
            if params[:tab]=="home"
              if params[:page] == "1"
                render partial: "main"
              else
                render partial: "min", :locals => {:ids_to_avoid=>params[:ids_to_avoid].split(','), :prefix_id=>"home"}, :layout => false
              end
            elsif params[:tab]=="net"
              if params[:page] == "1"
                render :partial => "net_main", :locals => {:scope => :net, :page=> params[:page], :sort_by=> params[:sort_by]||"popularity", :prefix_id=>"network"}, :layout => false
              else
                render :partial => "net_min", :locals => {:scope => :net, :page=> params[:page], :sort_by=> params[:sort_by]||"popularity", :prefix_id=>"network"}, :layout => false
              end
            end
        else
          #Non-Ajax call
          if params[:tab]=="catalogue"
            @default_categories = view_context.getDefaultCategories
          end
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