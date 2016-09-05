class ContestsController < ApplicationController

  before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update ]
  before_filter :find_contest

  def show
    page = params[:page] || "index"
    if view_context.lookup_context.template_exists?(page,"contests/templates/" + @contest.template,false)
      render "contests/templates/" + @contest.template + "/" + page
    end
  end


  private

  def find_contest
    if params[:name]
      @contest = Contest.find_by_name(params[:name])
    else
      @contest = Contest.find(params[:id])
    end
  end
  
end

