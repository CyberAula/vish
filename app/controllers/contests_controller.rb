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
    if view_context.lookup_context.template_exists?("new_resource","contests/templates/" + @contest.template + "/submissions",false)
      render "contests/templates/" + @contest.template + "/submissions/new_resource"
    else
      render "contests/submissions/new_resource"
    end
  end

  def submit
    return submit_return_with_error("Required param not found in submission","/") unless params["submission"].present? and params["submission"]["contest_category_id"].present? and params["submission"]["type"].present?

    contestCategory = ContestCategory.find_by_id(params["submission"]["contest_category_id"])
    return submit_return_with_error("Contest category not found","/") if contestCategory.nil?

    contest = contestCategory.contest
    return submit_return_with_error("Contest not found","/") if contest.nil?
    pathToReturn = @contest.getUrlWithName

    return submit_return_with_error(I18n.t("contest.submissions.contest_not_open"),pathToReturn) unless ["open"].include? contest.status
    contestSettings = contest.getParsedSettings
    if contestSettings["submission_require_enroll"]==="true"
      return submit_return_with_error(I18n.t("contest.submissions.require_enrollment"),pathToReturn) unless contest.enrolled_participants.include? current_subject.actor
    end

    case contestSettings["submission"]
    when "free"
    when "one_per_user"
      return submit_return_with_error(I18n.t("contest.submissions.one_per_user"),pathToReturn) if (contest.activity_objects.map{|ao| ao.author}.include? current_subject.actor)
    when "one_per_user_category"
      return submit_return_with_error(I18n.t("contest.submissions.one_per_user"),pathToReturn) if (contestCategory.activity_objects.map{|ao| ao.author}.include? current_subject.actor)
    end

    case params["submission"]["type"]
    when "Resource"
      return submit_return_with_error(I18n.t("contribution.messages.url_not_found"),pathToReturn) unless params["url"].present?
      object = ActivityObject.getObjectFromUrl(params["url"])
      return submit_return_with_error(I18n.t("contribution.messages.object_not_found"),pathToReturn) if object.nil?
    else
      return submit_return_with_error("Invalid contribution type",pathToReturn)
    end
    
    if object.new_record?
      #We need to create and save the object
      authorize! :create, object
      object.valid?
      return submit_return_with_error(object.errors.full_messages.to_sentence,pathToReturn) unless object.errors.blank? and object.save
      discard_flash
    else
      #Object already exists. Authorize user to submit that object.
      return submit_return_with_error(I18n.t("contribution.messages.object_not_yours"),pathToReturn) unless object.owner_id == current_subject.actor_id
      authorize! :update, object
    end

    ao = object.activity_object
    result = contestCategory.addActivityObject(ao)

    respond_to do |format|
      format.any {
        return submit_return_with_error(result,pathToReturn) if result.is_a? String
        #Return with success
        if request.xhr?
          return render :json => {}, :status => 200
        else
          discard_flash
          return redirect_to pathToReturn
        end
      }
    end
  end

  def submit_return_with_error(error,pathToReturn)
    if request.xhr?
      return render :json => {errors: [error]}, :status => 400
    else
      flash[:errors] = error
      return redirect_to pathToReturn
    end
  end

  def remove_submit
    pathToReturn = @contest.getUrlWithName
    return submit_return_with_error(I18n.t("contest.submissions.contest_not_open"),pathToReturn) unless ["open"].include? @contest.status
    return submit_return_with_error("Required param not found",pathToReturn) unless params["activity_object_id"].present?
    ao = ActivityObject.find_by_id(params["activity_object_id"])
    return submit_return_with_error("Activity Object not found",pathToReturn) if ao.nil?
    return submit_return_with_error("Activity Object was not submitted",pathToReturn) unless @contest.activity_objects.include? ao
    return submit_return_with_error("Activity Object is not yours",pathToReturn) unless ao.owner_id == current_subject.actor_id
    authorize! :destroy, ao.object

    @contest.categories.each do |c|
      c.deleteActivityObject(ao)
    end

    respond_to do |format|
      format.any {
        #Return with success
        if request.xhr?
          return render :json => {}, :status => 200
        else
          discard_flash
          return redirect_to pathToReturn
        end
      }
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

