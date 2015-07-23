# encoding: utf-8

class PrivateStudentGroupsController < ApplicationController

  before_filter :authenticate_user!
  skip_after_filter :discard_flash, :only => [:new, :create]

  def index
    redirect_to new_service_request_private_student_group_path unless (can? :create, PrivateStudentGroup.new)
    @privateStudentGroups = current_subject.private_student_groups
  end

  def show
    @privateStudentGroup = PrivateStudentGroup.find(params[:id])
    authorize! :show, @privateStudentGroup
  end

  def new
    authorize! :create, PrivateStudentGroup.new
  end

  def create
    authorize! :create, PrivateStudentGroup.new

    n = params["n"].to_i rescue 0
    if n > 0
      p = PrivateStudentGroup.new(params["private_student_group"])
      p.createGroupForSubject(current_subject,n)
      if p.new_record?
        flash[:errors] = I18n.t("private_student.creation_error")
      else
        flash[:success] = I18n.t("private_student.creation_success")
      end
      redirect_to private_student_groups_path
    end
  end

end