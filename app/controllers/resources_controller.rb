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

class ResourcesController < ApplicationController
  def search
    @found_resources = ThinkingSphinx.search params[:q], search_options.deep_merge!( { :classes => [Document, Embed, Link] } )
    render :layout => false
  end

  private
  def search_options
    opts = search_scope_options

    # profile_subject
    if profile_subject.present?
      opts.deep_merge!( { :with => { :owner_id => profile_subject.actor_id } } )
    end

    # Authentication
    opts.deep_merge!({ :with => { :relation_ids => Relation.ids_shared_with(current_subject) } } )

    # Pagination
    opts.merge!({
      :order => :created_at,
      :sort_mode => :desc,
      :per_page => params[:per_page] || 20,
      :page => params[:page]
    })

      opts
    end

  def search_scope_options
    if params[:scope].blank? || ! user_signed_in?
      return {}
    end

    case params[:scope]
    when "me"
      { :with => { :author_id => [ current_subject.author_id ] } }
    when "net"
      { :with => { :author_id => current_subject.following_actor_ids } }
    when "other"
      { :without => { :author_id => current_subject.following_actor_and_self_ids } }
    else
      raise "Unknown search scope #{ params[:scope] }"
    end
  end

end
