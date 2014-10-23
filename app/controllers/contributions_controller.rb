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

class ContributionsController < ApplicationController
  before_filter :authenticate_user!
  inherit_resources

  #############
  # REST methods
  #############

  def new
    super do |format|
      format.html {
        render "new"
      }
    end
  end

  def create
    params["contribution"] ||= {}

    if params[:writing]
      params["writing"].permit!
      params["writing"]["scope"] ||= "0" #public
      params["writing"]["owner_id"] = current_subject.actor_id
      params["writing"]["author_id"] = current_subject.actor_id
      params["writing"]["user_author_id"] = current_subject.actor_id
      ao = Writing.new(params["writing"])
      ao.save!
    elsif params[:picture]
        params["picture"].permit!
        params["picture"]["scope"] ||= "0" #public
        params["picture"]["owner_id"] = current_subject.actor_id
        params["picture"]["author_id"] = current_subject.actor_id
        params["picture"]["user_author_id"] = current_subject.actor_id
        ao = Document.new(params["picture"])
        ao.save!
    else
      #no activity_object associated, throw error
      #TODO
    end

    params["contribution"]["activity_object_id"] = ao.activity_object_id
    super do |format|
      format.html {
        unless resource.errors.blank?
          flash[:errors] = resource.errors.full_messages.to_sentence
        else
          discard_flash
        end
        
        redirect_to workshop_path(resource.workshop)
      }
    end
  end

  def edit
    
  end
 

  private

  def allowed_params
    [:wa_assignment_id, :activity_object_id]
  end

end