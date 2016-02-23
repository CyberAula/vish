class CoursesController < ApplicationController  
  include SocialStream::Controllers::Objects
  skip_load_and_authorize_resource :only => [:attachment]

  def new
    new! do |format|
      format.any {
        render 'new'
      }
    end
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
    [:start_date, :end_date, :restricted, :restriction_email, :restriction_password, :url, :course_password, :avatar, :attachment]
  end
end

