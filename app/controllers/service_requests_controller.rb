# encoding: utf-8

class ServiceRequestsController < ApplicationController

  before_filter :authenticate_user!
  skip_after_filter :discard_flash, :only => [:new, :create, :accept, :destroy]

  def show
    @request = ServiceRequest.find(params[:id])
    respond_to do |format|
      format.js
    end
  end
  
  def new
    respond_to do |format|
      format.js 
    end
  end

  def duplicated
    respond_to do |format|
      format.js 
    end
  end

  def attachment
    s = ServiceRequest::PrivateStudentGroup.find(params[:id])
    authorize! :show, s

    respond_to do |format|
      format.any {
        return head(:not_found) unless s.attachment.exists?
        send_file s.attachment.path,
                 :filename => s.attachment.original_filename,
                 :disposition => "inline",
                 :type => s.attachment_content_type
      }
    end
  end

  def accept
    s = ServiceRequest.find(params[:id])
    authorize! :update, s
    s.status = "Accepted"
    s.afterAccept
    s.save!
    flash[:success] = "The request was succesfully accepted."
    redirect_to "/admin/requests"
  end

  def destroy
    s = ServiceRequest.find(params[:id])
    authorize! :destroy, s
    s.destroy
    flash[:success] = "The request was succesfully deleted."
    redirect_to "/admin/requests"
  end

end