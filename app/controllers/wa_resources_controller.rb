# Copyright 2011-2012 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of ViSH (Virtual Science Hub).
#
# ViSH is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ViSH is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ViSH.  If not, see <http://www.gnu.org/licenses/>.

class WaResourcesController < ApplicationController

  before_filter :authenticate_user!
  inherit_resources

  #############
  # REST methods
  #############

  def create
    params["wa_resource"] ||= {}
    unless params["url"].blank?
      the_resource = ActivityObject.getObjectFromUrl(params["url"])
      unless the_resource.nil? or the_resource.activity_object.nil? or !VishConfig.getAvailableAllResourceModels.include? the_resource.activity_object.object_type
        params["wa_resource"]["activity_object_id"] = the_resource.activity_object.id
      end
    end 
    
    super do |format|
      format.html {
        redirect_to edit_workshop_path(resource.workshop)
      }
    end
  end

  def update
    super do |format|
      format.html {
        redirect_to edit_workshop_path(resource.workshop)
      }
    end
  end

  def destroy
    destroy! do |format|
      format.all { redirect_to user_path(current_subject) }
    end
  end


  private

  def allowed_params
    [:workshop_id, :activity_object_id]
  end

end