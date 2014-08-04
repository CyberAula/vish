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

  skip_load_and_authorize_resource :only => [:api_excursion_suggestions]

  # Enable CORS (http://www.tsheffler.com/blog/?p=428) for the recommender system
  before_filter :cors_preflight_check, :only => [:api_excursion_suggestions]
  after_filter :cors_set_access_control_headers, :only => [:api_excursion_suggestions]

  #############
  # CORS
  #############
  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    headers['Access-Control-Max-Age'] = "1728000"
  end

  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.
  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version'
      headers['Access-Control-Max-Age'] = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end

  ##################
  # API REST
  ##################
  def api_excursion_suggestions
    if params[:excursion_id]
      current_excursion =  Excursion.find(params[:excursion_id]) rescue nil
    end
    excursions = RecommenderSystem.excursion_suggestions(current_subject,current_excursion)

    respond_to do |format|
      format.any { 
        results = []
        excursions.map { |ex| results.push(ex.reduced_json(self)) }
        render :json => results
      }
    end
  end

end