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
  skip_authorize_resource :only => :search
  include SocialStream::Controllers::Objects

  def new
    new! do |format|
      format.full { render :layout => 'iframe' }
    end
  end


  def create
    super do |format|
      format.all { render :json => resource }
    end
  end


  def show
    show! do |format|
      format.full { render :layout => 'iframe' }
      format.json { render :json => resource }
    end
  end


  def search
    params[:scope] ||= :net
    render :layout => false, :locals  => { :excursions => do_search(current_subject, params[:q], params[:scope]) }
  end


  private

  def do_search subject, query_str, scope, limit=4
    # This is similar to some code at the Home Helper, but painfully and fundamentally different
    # For one, this does need Sphinx running in your machine to render any results at all.
    # Also, it's slightly less efficient, since it fetches the results, the reorders them rather
    #       than doing a simple SQL query.

    following_ids = subject.following_actor_ids
    following_ids |= [ subject.actor_id ]

    case scope.to_sym
    when :me
      ids = [ subject.actor_id ]
    when :net
      ids = following_ids
    when :more
      ids = Actor.all - following_ids
    end
    Excursion.search(query_str, :with => { :author_id => ids }).sort_by!{|e| e.created_at}.reverse.first(limit)
  end


  def hack_auth
    params["excursion"] ||= {}
    params["excursion"]["relation_ids"] = [Relation::Public.instance.id]
    params["excursion"]["owner_id"] = current_subject.actor_id
  end
end
