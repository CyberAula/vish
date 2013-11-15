class SearchController < ApplicationController
  include ActionView::Helpers::SanitizeHelper
  include SearchHelper

  RESULTS_SEARCH_PER_PAGE=12
  MIN_QUERY=2
  def index
    headers['Last-Modified'] = Time.now.httpdate

    @search_result =
      if params[:q].blank?
        search :extended # TODO: this should have :match_mode => :fullscan for efficiency
      elsif params[:q].strip.size < MIN_QUERY
        []
      elsif params[:mode].eql? "header_search"
        search :quick
      else
        search :extended
      end

    respond_to do |format|
      format.html {
        if params[:mode] == "header_search"
          render :partial => "header_search"
        end
      }

      format.json {
        json_obj = (
          params[:type].present? ?
          { params[:type].pluralize => @search_result } :
          @search_result
        )

        render :json => json_obj
      }

      format.js
    end
  end

  private

  def search mode="extended"
    results = ThinkingSphinx.search params[:q], vish_search_options(mode, params[:type], RESULTS_SEARCH_PER_PAGE, params[:page])
    results = Kaminari.paginate_array(results).page(1).per(7) if mode.to_s.eql? "quick"
    results
  end
end
