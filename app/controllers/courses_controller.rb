class CoursesController < ApplicationController  
  include SocialStream::Controllers::Objects
  skip_load_and_authorize_resource :only => [:attachment]
  skip_after_filter :discard_flash, :only => [:join, :leave]

  def index
    @courses = Course.all
  end

  def new
    new! do |format|
      format.any {
        render 'new'
      }
    end
  end

  def join
    if !@course.restriction_email.empty? && !(current_user.email.ends_with? @course.restriction_email)
      flash[:errors] = t('course.flash.not_allowed')
      return redirect_to course_path(@course)
    end
    if !@course.users.include? current_user
      flash[:success] = t('course.flash.join_success')
      @course.users << current_user
    end
    redirect_to course_path(@course)
  end

  def leave
    if @course.users.include? current_user
      flash[:success] = t('course.flash.leave_success')
      @course.users.delete(current_user)
    end
    redirect_to course_path(@course)
  end

  def attachment
    c = Course.find(params[:id])

    respond_to do |format|
      format.any {
        return head(:not_found) unless c.attachment.exists?
        send_file c.attachment.path,
                 :filename => c.attachment.original_filename,
                 :disposition => "inline",
                 :type => c.attachment_content_type
      }
    end
  end

  private

  def allowed_params
    [:start_date, :end_date, :restricted, :restriction_email, :restriction_password, :url, :course_password, :avatar, :attachment, :language, :license_id, :age_min, :age_max, :scope, :avatar, :tag_list=>[]]
  end
end

