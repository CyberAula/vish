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
  include HomeHelper

  def search
    headers['Last-Modified'] = Time.now.httpdate

    @found_resources = if params[:scope].present? and params[:scope] == "like"
      subject_resources search_subject, { :scope => :like, :limit => params[:per_page].to_i } # This WON'T search... it's a scam
    elsif params[:live].present?
      ThinkingSphinx.search params[:q], search_options.deep_merge!( { :classes => [Embed, Swf, Link] } )
    elsif params[:object].present?
      ThinkingSphinx.search params[:q], search_options.deep_merge!( { :classes => [Embed, Swf, Officedoc, Link] } )
    else
      ThinkingSphinx.search params[:q], search_options.deep_merge!( { :classes => [Officedoc, Swf, Embed, Link, Video, Audio] } )
    end
    respond_to do |format|
      format.html {
         if @found_resources.size == 0 and params[:scope].present? and params[:scope] == "like"
           render :partial => "common_documents/fav_zero_screen"
         else
           render :layout => false
         end
      }
      format.json {
        if params[:object].present?
          render :partial => 'objects/object_search_result'
        else
          render :json => @found_resources.to_json(helper: self)
        end
      }
    end
  end

  def recommended
    render :partial => "common_documents/filter_results", :locals => {:documents => current_subject.resource_suggestions(6) }
  end

  private
  def search_options
    opts = search_scope_options

    # search only live resources
    if params[:live].present?
      opts.deep_merge!( { :with => { :live => true } } )
    end

    # Pagination
    opts.merge!({
      :order => :created_at,
      :sort_mode => :desc,
      :per_page => params[:per_page] || 20,
      :page => params[:page]
    })

      opts
  end

  def search_subject
    return current_subject if request.referer.blank?
    @search_subject ||=
      ( Actor.find_by_slug(URI(request.referer).path.split("/")[2]) || current_subject )
  end

  def search_scope_options
    if params[:scope].blank? || search_subject.blank?
      return {}
    end

    case params[:scope]
    when "me"
      { :with => { :author_id => [ search_subject.id ] } }
    when "net"
      { :with => { :author_id => search_subject.following_actor_ids } }
    when "other"
      { :without => { :author_id => search_subject.following_actor_and_self_ids } }
    else
      raise "Unknown search scope #{ params[:scope] }"
    end
  end

end
