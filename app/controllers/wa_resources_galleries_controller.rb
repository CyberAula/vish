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

class WaResourcesGalleriesController < ApplicationController

  before_filter :authenticate_user!
  inherit_resources

  load_and_authorize_resource
  skip_after_filter :discard_flash, :only => [:create, :update]

  #############
  # REST methods
  #############

  def create
    super do |format|
      format.html {
         unless resource.errors.blank?
          flash[:errors] = resource.errors.full_messages.to_sentence
        else
          discard_flash
        end
        redirect_to edit_workshop_path(resource.workshop)
      }
    end
  end

  def update
    params["wa_resources_gallery"] ||= {}
    ao_ids = resource.activity_object_ids

    unless params["url"].blank?
      the_resource = ActivityObject.getObjectFromUrl(params["url"])
      unless the_resource.nil? or the_resource.activity_object.nil?
        ao_ids << the_resource.activity_object.id
      end
      params.delete "url"
    end

    unless params["remove_activity_object_id"].blank?
      ao_ids.reject!{|id| id.to_s==params["remove_activity_object_id"]}
    end

    ao_ids.uniq!
    params["wa_resources_gallery"]["activity_object_ids"] = ao_ids

    super do |format|
      format.html {
         unless resource.errors.blank?
          flash[:errors] = resource.errors.full_messages.to_sentence
        else
          discard_flash
        end
        redirect_to edit_workshop_path(resource.workshop)
      }
    end
  end

  def add_resource
    resource = WaResourcesGallery.find(params[:id])
    respond_to do |format|
      format.html {
        render :form_add_resource, :layout => false
      }
    end
  end

  def destroy
    destroy! do |format|
      format.all {
        redirect_to edit_workshop_path(resource.workshop)
      }
    end
  end


  private

  def allowed_params
    [:workshop_id, :activity_object_ids=>[]]
  end

end