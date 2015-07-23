# encoding: utf-8

class ServiceRequestsController < ApplicationController

  before_filter :authenticate_user!
  skip_after_filter :discard_flash, :only => [:new, :create]

  def duplicated
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

end