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
    binding.pry    
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

  def edit
    
  end

 

  private

  def allowed_params
    [:wa_assignment_id, :activity_object_id]
  end

end