class ContestsController < ApplicationController

  before_filter :authenticate_user!, :only => [ :new, :create, :edit, :update, :enroll, :disenroll ]
  before_filter :find_contest
  skip_after_filter :discard_flash, :only => [:enroll, :disenroll]

  def show
    page = params[:page] || "index"
    if view_context.lookup_context.template_exists?(page,"contests/templates/" + @contest.template,false)
      render "contests/templates/" + @contest.template + "/" + page
    end
  end

  def enroll
    result = @contest.enrollActor(current_subject.actor)
    unless result.nil?
      flash[:success] = t('contest.enrollment_success')
    else
      flash[:errors] = t('contest.enrollment_failure')
    end
    redirect_to(@contest.getUrlWithName)
  end

  def disenroll
    result = @contest.disenrollActor(current_subject.actor)
    unless result.nil?
      flash[:success] = t('contest.disenrollment_success')
    else
      flash[:errors] = t('contest.disenrollment_failure')
    end
    redirect_to(@contest.getUrlWithName)
  end

  def new_resource_submission
    render "contests/submissions/new_resource"
  end

  def submit
    #TODO
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

