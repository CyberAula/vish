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

class ExcursionsController < ApplicationController
  # Quick hack for bypassing social stream's auth
  before_filter :hack_auth, :only => [ :new, :create]
  include HomeHelper
  skip_authorize_resource :only => :filter
  include SocialStream::Controllers::Objects

  def new
    new! do |format|
      format.full { render :layout => 'iframe' }
    end
  end


  def show
    show! do |format|
      format.full { render :layout => 'iframe' }
    end
  end


  def filter
    params[:scope] ||= 'me'
    render :partial => "excursions/filter_results",
           :locals  => { :excursions => current_subject_excursions({ :scope => params[:scope], :query => params[:q] }) }
  end


  private

  def hack_auth
    params["excursion"] ||= {}
    params["excursion"]["_relation_ids"] = [Relation::Public.instance.id]
    params["excursion"]["owner_id"] = current_subject.actor_id
  end
end
