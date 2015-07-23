# encoding: utf-8

class ServiceRequests::PrivateStudentGroupsController < ApplicationController

  before_filter :authenticate_user!
  skip_after_filter :discard_flash, :only => [:new, :create]

  def new
    authorize! :create, ServiceRequest::PrivateStudentGroup.new
  end

  def create
    authorize! :create, ServiceRequest::PrivateStudentGroup.new
    redirect_to user_path(current_subject)
  end

end