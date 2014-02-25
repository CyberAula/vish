class SearchController < ApplicationController
  include ActionView::Helpers::SanitizeHelper

  RESULTS_SEARCH_PER_PAGE=24

  def index
    @search_result =
      if params[:q].blank?
        search :extended # TODO: this should have :match_mode => :fullscan for efficiency
      elsif params[:q].strip.size < SocialStream::Search::MIN_QUERY
        Kaminari.paginate_array([])
      elsif params[:mode] == "quick"
        search :quick
      else
        search :extended
      end

    respond_to do |format|
      format.html {
        if request.xhr?
          if params[:mode] == "quick"
            render partial: "quick"
          else
            render partial: 'results'            
          end
        end
      }
      
      format.json {
        json_obj = (
          params[:type].present? ?
          { params[:type].pluralize => @search_result.compact } :
          @search_result.compact
        )

        render :json => json_obj.to_json(helper: self)
      }

      format.js
    end
  end

  private

  def search mode
    page =  ( mode == :quick ? 1 : params[:page] )
    limit = ( mode == :quick ? 7 : RESULTS_SEARCH_PER_PAGE )
    the_query = nil
    order = 'popularity DESC'

    if(params[:q])
      the_query_or = Riddle.escape(params[:q].strip).gsub(" ", " | ")
      the_query = "\"^" + params[:q] + "$\" | \"" + params[:q] + "\" | (" + the_query_or + ")"
      order = nil #so it searches exact first
    end

    SocialStream::Search.search(the_query, 
      current_subject, 
      mode: mode, 
      key: params[:type],
      page: page, 
      limit: limit,
      order: order)

  end
end

          