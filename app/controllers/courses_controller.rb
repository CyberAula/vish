class CoursesController < ApplicationController  
  include SocialStream::Controllers::Objects
  before_filter :authenticate_user!, :except => [:show, :attachment, :index]
  skip_authorize_resource :only => [:attachment, :join, :leave]
  skip_before_filter :store_location, :only => :attachment
  skip_after_filter :discard_flash, :only => [:join, :leave]

  def index
    if current_user && params[:user_id].present?
      @courses = current_user.courses
    else
      @courses = Course.all
    end
  end

  def new
    new! do |format|
      format.any {
        render 'new'
      }
    end
  end

  def join
    is_ok = false
    if @course.restricted
      if @course.restriction_email.present? && (current_user.email.ends_with? @course.restriction_email)
        is_ok = true
      elsif @course.restriction_password.present? && params[:password].present? &&  params[:password]== @course.restriction_password
        is_ok = true
      else
        flash[:errors] = t('course.flash.not_allowed')
      end
    else
      is_ok = true
    end

    if @course.users.include? current_user
      flash[:errors] = t('course.flash.already_in')
      is_already_in = true
    else      
      is_already_in = false
    end

    if is_ok && !is_already_in
        flash[:success] = t('course.flash.join_success')
        @course.users << current_user
        #we send the user the welcome email
        CourseNotificationMailer.user_welcome_email(current_user, @course)
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
    [:start_date, :end_date, :restricted, :restriction_email, :restriction_password, :url, :course_password, :closed, :avatar, :attachment, :language, :license_id, :age_min, :age_max, :scope, :avatar, :tag_list=>[]]
  end
end

