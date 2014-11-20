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

# ViSH Recommender System

class RecommenderController < ApplicationController

  skip_load_and_authorize_resource :only => [:api_resource_suggestions]

  # Enable CORS
  ApplicationController.enable_cors([:api_resource_suggestions])


  ##################
  # API REST
  ##################
  def api_resource_suggestions
    if params[:resource_id]
      current_resource =  ActivityObject.find(params[:resource_id]).object rescue nil
    end
    resources = RecommenderSystem.resource_suggestions(current_subject,current_resource)
    respond_to do |format|
      format.any { 
        results = []
        resources.map { |r| results.push(r.activity_object.search_json(self)) }
        render :json => results, :content_type => "application/json"
      }
    end
  end

end