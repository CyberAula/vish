Vish::Application.configure do
  
  #Init Catalogue
  config.after_initialize do

    unless config.APP_CONFIG['catalogue'].is_a? Hash
      config.catalogue = {}
    else
      config.catalogue = config.APP_CONFIG['catalogue']
    end
    config.catalogue['mode'] = "matchany" unless ["matchany","matchtag"].include? config.catalogue['mode']
    config.catalogue["qualityThreshold"] = nil unless config.catalogue["qualityThreshold"].is_a? Numeric

    #Specify the categories of the catalogue
    unless config.catalogue["categories"].is_a? Array and !config.catalogue["categories"].blank?
        #Fill with popular tags
        config.catalogue["categories"] = ActivityObject.tag_counts(:order => "count desc").first(10).map{|t| t.name} if ActiveRecord::Base.connection.table_exists?('tags')
    end
    config.catalogue["categories"] = [] unless config.catalogue["categories"].is_a? Array
    
    #Category_keywords is a hash with the keywords of each category
    config.catalogue["category_keywords"] = Hash.new
    if config.catalogue['mode'] == "matchtag"
        #Category_tag_ids is a hash with the ids of the tags of each category
        config.catalogue["category_tag_ids"] = Hash.new
    end
    #Keywords is an array with all the existing keywords/tags
    config.catalogue["keywords"] = []
    
    #Combine categories and add extra terms
    if config.catalogue["combinedCategories"].is_a? Hash
        combinedCategories = config.catalogue["combinedCategories"]
    else
        combinedCategories = {}
    end
    if config.catalogue["extraTerms"].is_a? Hash
        extraTerms = config.catalogue["extraTerms"]
    else
        extraTerms = {}
    end

    #Build category keywords
    config.catalogue["categories"].each do |c1|
        config.catalogue["category_keywords"][c1] = []

        allCategories = [c1]

        #1. Combined categories
        if combinedCategories[c1].is_a? Array and combinedCategories[c1].map{|e| e.is_a? String}.uniq == [true]
            allCategories.concat(combinedCategories[c1])
            allCategories.uniq!
        end

        #2. Internationalization of categories
        allCategories.each do |c2|
            addC2flag = true
            I18n.available_locales.each do |lang|
                c2K = I18n.t("catalogue.categories." + c2, :locale => lang, :default => "translationMissing")
                unless c2K == "translationMissing"
                    addC2flag = false
                    config.catalogue["category_keywords"][c1].push(c2K)
                end
            end
            config.catalogue["category_keywords"][c1].push(c2) if addC2flag
        end

        #3. Extra terms
        allExtraTerms = []
        allCategories.each do |c3|
            allExtraTerms.concat(extraTerms[c3]) if extraTerms[c3].is_a? Array and extraTerms[c3].map{|e| e.is_a? String}.uniq == [true]
        end
        allExtraTerms.uniq!

        #2. Internationalization of extra terms
        allExtraTerms.each do |c4|
            addC4flag = true
            I18n.available_locales.each do |lang|
                c4K = I18n.t("catalogue.extras." + c4, :locale => lang, :default => "translationMissing")
                unless c4K == "translationMissing"
                    config.catalogue["category_keywords"][c1].push(c4K)
                end
            end
            config.catalogue["category_keywords"][c1].push(c4) if addC4flag
        end

        config.catalogue["category_keywords"][c1].reject!{|c| c=="translationMissing"}
        config.catalogue["category_keywords"][c1].uniq!

        config.catalogue["keywords"].concat(config.catalogue["category_keywords"][c1])

        if config.catalogue['mode'] == "matchtag" and (ActiveRecord::Base.connection.table_exists?('tags') and ActiveRecord::Base.connection.column_exists?(:tags, :plain_name))
            allActsAsTaggableOnTags = ActsAsTaggableOn::Tag.where("plain_name IN (?)", config.catalogue["category_keywords"][c1].map{|tag| ActsAsTaggableOn::Tag.getPlainName(tag)})
            config.catalogue["category_tag_ids"][c1] = allActsAsTaggableOnTags.map{|t| t.id}
        end
    end

    config.catalogue["keywords"].uniq!
  end

end