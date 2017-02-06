# encoding: utf-8

###############
# ViSH Search Engine
###############

class Search

  # Usage example: Search.search({:query=>"biology", :n=>10})
  def self.search(options={})

    #Specify searchTerms
    case options[:query].class.name
    when "String"
      searchTerms = forceEncoding(options[:query]).split(" ")
    when "Array"
      searchTerms = options[:query].map{|str| forceEncoding(str).strip}.reject{|s| s==""}
    else
      searchTerms = []
    end

    #Browse or search
    browse = searchTerms.blank?

    unless browse
      #Sanitize search terms
      searchTerms = searchTerms.map{|st| Riddle.escape(st) }
      #Remove keywords with less than 3 characters
      searchTerms = searchTerms.reject{|s| s.length < 3}
      #Perform an OR search
      searchTerms = searchTerms.join(" ")
    end

    #Specify search options
    opts = {}

    if options[:n].is_a? Integer
      n = [Vish::Application::config.max_matches,options[:n]].min
    else
      unless options[:page].nil?
        n = 16    #default results when pagination is requested
      else
        n = Vish::Application::config.max_matches #default (All possible results found)
      end
    end

    #Logical conector: OR
    opts[:match_mode] = :any
    opts[:rank_mode] = :wordcount
    opts[:per_page] = n
    metricsParams = Vish::Application::config.metrics_relevance_ranking
    opts[:field_weights] = metricsParams[:field_weights]

    opts[:max_matches] = Vish::Application::config.max_matches

    opts[:page] = options[:page].to_i unless options[:page].nil?
    opts[:order] = options[:order] if options[:order].is_a? String

    if options[:models].is_a? Array
      opts[:classes] = options[:models]
    else
      opts[:classes] = SocialStream::Search.models(:extended)
    end

    opts[:with] = {}
    opts[:with_all] = {}
    
    unless !options[:subject].nil? and options[:subject].admin?
      #Only 'Public' objects, drafts and other private objects are not searched.
      opts[:with][:relation_ids] = Relation.ids_shared_with(nil)
      opts[:with][:scope] = 0
    end
    
    #Data range filter
    if options[:startDate] or options[:endDate]
      if options[:startDate].class.name != "Time"
        #e.g. Time.parse("21-07-2014 11:41:00")
        startDate = Time.parse(options[:startDate]) rescue 1000.year.ago
      else
        startDate = options[:startDate]
      end
      if options[:endDate].class.name != "Time"
        endDate = Time.parse(options[:endDate]) rescue Time.now
      else
        endDate = options[:endDate]
      end

      opts[:with][:created_at] = startDate..endDate
    end

    #Filter by language
    if options[:language]
      if options[:language].is_a? String
        options[:language] = [options[:language]]
      end
      if options[:language].is_a? Array
        opts[:with][:language] = options[:language].map{|language| language.to_s.to_crc32}
      end
    end

    #Filter by quality score
    if options[:qualityThreshold]
      qualityThreshold = [[0,options[:qualityThreshold].to_f].max,10].min rescue 0
      qualityThreshold = qualityThreshold*100000
      opts[:with][:qscore] = qualityThreshold..1000000
    end

    #Filter by tags
    if options[:tags]
      if options[:tags].is_a? String
        options[:tags] = options[:tags].split(",")
      end

      if options[:tags].is_a? Array
        tag_ids = ActsAsTaggableOn::Tag.find_all_by_name(options[:tags]).map{|t| t.id}
        tag_ids = [-1] if tag_ids.blank?
        opts[:with_all][:tag_ids] = tag_ids
      end
    elsif options[:tag_ids]
      if options[:tag_ids].is_a? String
        options[:tag_ids] = options[:tag_ids].split(",")
      end

      if options[:tag_ids].is_a? Array
        opts[:with_all][:tag_ids] = [options[:tag_ids]]
      end
    end

    #Filter by age range
    if options[:age_min] or options[:age_max]

      unless options[:age_min].blank?
        ageMin = options[:age_min].to_i rescue 0
      else
        ageMin = 0
      end

      unless options[:age_max].blank?
        ageMax = options[:age_max].to_i rescue 100
      else
        ageMax = 100
      end

      ageMax = [[100,ageMax].min,0].max
      ageMin = [ageMin,ageMax].min

      opts[:with][:age_min] = 0..ageMax
      opts[:with][:age_max] = ageMin..100
    end

    #Filter by license
    if options[:license].is_a? String
      #Remove models without licenses
      opts[:classes] = (opts[:classes] - [User,Event,Embed,Link,Category])
      license = License.find_by_key(options[:license])
      unless license.nil?
        opts[:with][:license_id] = license.id
      end
    end

    #Filter by categories
    if options[:category_ids].is_a? String
      options[:category_ids] = options[:category_ids].split(",")
    end

    if options[:category_ids].is_a? Array
      opts[:with][:tag_ids] = []
      options[:category_ids].each do |category|
        if Vish::Application.config.catalogue["category_tag_ids"][category].is_a? Array
          opts[:with][:tag_ids].push(Vish::Application.config.catalogue["category_tag_ids"][category])
        end
      end
      opts[:with][:tag_ids] = opts[:with][:tag_ids].flatten.uniq
    end
    
    opts[:without] = {}
    if options[:subjects_to_avoid].is_a? Array
      options[:subjects_to_avoid] = options[:subjects_to_avoid].compact
      unless options[:subjects_to_avoid].empty?
        opts[:without][:owner_id] = Actor.normalize_id(options[:subjects_to_avoid])
      end
    end

    if options[:ids_to_avoid].is_a? Array
      options[:ids_to_avoid] = options[:ids_to_avoid].compact
      unless options[:ids_to_avoid].empty?
        opts[:without][:id] = options[:ids_to_avoid]
      end
    end

    if options[:ao_ids_to_avoid].is_a? Array
      options[:ao_ids_to_avoid] = options[:ao_ids_to_avoid].compact
      unless options[:ao_ids_to_avoid].empty?
        opts[:without][:activity_object_id] = options[:ao_ids_to_avoid]
      end
    end

    if opts[:classes].blank?
      #opts[:classes] blank will search for all classes by default. Set scope to -1 to return empty results.
      opts[:with][:scope] = -1
    end

    # (Try to) Avoid nil results (See http://pat.github.io/thinking-sphinx/searching.html#nils)
    opts[:retry_stale] = true
    

    if browse==true
      #Browse
      opts[:match_mode] = :extended
      #Browse can't order by relevance. Set ranking by default.
      opts[:order] = 'ranking DESC' if opts[:order].nil?
      #Blank search terms
      searchTerms = ""
    else
      queryLength = searchTerms.scan(/\w+/).size

      #Search for some search terms
      if queryLength > 0 and opts[:order].nil?
        # Order by custom weight
        opts[:sort_mode] = :expr

        # Ordering by custom weight
        # Documentation: http://pat.github.io/thinking-sphinx/searching/ts2.html#sorting
        # Discussion: http://sphinxsearch.com/forum/view.html?id=3675
        # ThinkingSphinx..search(searchTerms, opts).results[:matches].map{|m| m[:weight]}
        # ThinkingSphinx.search(searchTerms, opts).results[:matches].map{|m| m[:attributes]["@expr"]}
        orderByRelevance = "1000000*MIN(1,((@weight)/(" + opts[:field_weights][:title].to_s + "*MIN(title_length," + queryLength.to_s + ") + " + opts[:field_weights][:description].to_s + "*MIN(desc_length," + queryLength.to_s + ") + " + opts[:field_weights][:tags].to_s + "*MIN(tags_length," + queryLength.to_s + "))))"
        opts[:order] = metricsParams[:w_rquery].to_s + "*" + orderByRelevance + " + " + metricsParams[:w_popularity].to_s + "*popularity + " + metricsParams[:w_qscore].to_s + "*qscore"
      else
        # Search with an specified order.
        # Search for words with a length shorten than 3 characraters. In this case, the search engine will return empty results.
      end
    end
    opts[:order] = '@random' if opts[:order]=="random"

    return ThinkingSphinx.search searchTerms, opts
  end

  def self.forceEncoding(str)
    str = str.force_encoding('UTF-8')
    return str if str.valid_encoding?
    str.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  end

end