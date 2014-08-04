class ActivityObjectController < ApplicationController
  
  def avatar
    ao = ActivityObject.find_by_id(params[:id])
    unless ao.nil? or ao.object.nil?
      authorize! :show, ao.object
      send_file ao.avatar.path, type: ao.avatar_content_type, disposition: "inline"
    else
      send_file Rails.root.to_s + '/app/assets/images/logos/original/ao-default.png', type: "image/png", disposition: "inline"
    end
  end

end