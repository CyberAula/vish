# encoding: utf-8

class PrivateStudentGroupsController < ApplicationController

  before_filter :authenticate_user!
  skip_after_filter :discard_flash, :only => [:new, :create]

  def new
    authorize! :create, PrivateStudentGroup.new
  end

  def create
    authorize! :create, PrivateStudentGroup.new

    n = params["n"].to_i rescue 0
    if n > 0
      p = PrivateStudentGroup.new
      p.createGroupForSubject(current_subject,n)
      if p.new_record?
        flash[:errors] = I18n.t("private_student.creation_error")
      else
        flash[:success] = I18n.t("private_student.creation_success")
      end
      redirect_to user_path(current_subject)
    end
  end

end