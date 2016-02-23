class CoursesController < ApplicationController  
  include SocialStream::Controllers::Objects


  def new
    new! do |format|
      format.any {
        render 'new'
      }
    end
  end

  private

  def allowed_params
    [:start_date, :end_date, :restricted, :restriction_email, :restriction_password, :url, :course_password]
  end
end

