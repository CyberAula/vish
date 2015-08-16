# encoding: utf-8

class ServiceRequest::PrivateStudentGroupsController < ServiceRequestsController

  def new
    authorize! :create, ServiceRequest::PrivateStudentGroup.new
    if request.xhr?
      render(:partial => "duplicated", :layout => false) if ((can? :create, PrivateStudentGroup.new) or (current_subject.service_requests.select{|s| s.type=="ServiceRequest::PrivateStudentGroup"}.length > 0))
    else
      redirect_to (Rails.application.routes.url_helpers.service_request_private_student_groups_path + "/duplicated") if ((can? :create, PrivateStudentGroup.new) or (current_subject.service_requests.select{|s| s.type=="ServiceRequest::PrivateStudentGroup"}.length > 0))
    end
  end

  def create
    authorize! :create, ServiceRequest::PrivateStudentGroup.new
    s = ServiceRequest::PrivateStudentGroup.new(params["service_request_private_student_group"])
    s.save!
    redirect_to user_path(current_subject)
  end

end