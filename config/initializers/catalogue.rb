Vish::Application.configure do
  
  #Init Catalogue
  config.after_initialize do

    #Specify the categories of the catalogue
    config.catalogue["categories"] = ["art","biology","chemistry","citizenship","computerScience","economics","education","engineering","foreignLanguages","generalCulture","geography","geology","history","humanities","literature","maths","music","naturalScience","physics","technology"]
    config.catalogue["default_categories"] = ["maths","physics","biology","technology"]
    
    #Category_keywords is a hash with the keywords of each category
    config.catalogue["category_keywords"] = Hash.new
    if config.catalogue['mode'] == "matchtag"
        #Category_tag_ids is a hash with the ids of the tags of each category
        config.catalogue["category_tag_ids"] = Hash.new
    end
    #Keywords is an array with all the existing keywords/tags
    config.catalogue["keywords"] = []
    
    #Combine categories and add extra terms
    combinedCategories = {"biology" => ["naturalScience","EnvironmentalStudies"], "engineering"=>["computerScience"], "generalCulture" => ["humanities","history","literature"], "humanities"=>["history","literature"], "naturalScience" => ["EnvironmentalStudies"], "technology"=>["engineering","computerScience"]}
    extraTerms = {"education"=>["eLearning","learning","teaching"],"foreignLanguages"=>["listening"],"maths"=>["math"]}

    #Build catalogue search terms
    
    config.catalogue["categories"].each do |c1|
        config.catalogue["category_keywords"][c1] = []

        allCategories = [c1]
        unless combinedCategories[c1].nil?
            allCategories.concat(combinedCategories[c1])
            allCategories.uniq!
        end

        allCategories.each do |c2|
            I18n.available_locales.each do |lang|
                config.catalogue["category_keywords"][c1].push(I18n.t("catalogue.categories." + c2, :locale => lang, :default => "translationMissing"))
            end
        end

        allExtraTerms = []
        allCategories.each do |c3|
          unless extraTerms[c3].nil?
              allExtraTerms.concat(extraTerms[c3])
          end
        end
        allExtraTerms.uniq!

        allExtraTerms.each do |c4|
            I18n.available_locales.each do |lang|
                config.catalogue["category_keywords"][c1].push(I18n.t("catalogue.extras." + c4, :locale => lang, :default => "translationMissing"))
            end
        end

        config.catalogue["category_keywords"][c1].reject!{|c| c=="translationMissing"}
        config.catalogue["category_keywords"][c1].uniq!

        config.catalogue["keywords"].concat(config.catalogue["category_keywords"][c1])

        if config.catalogue['mode'] == "matchtag"
            config.catalogue["category_tag_ids"][c1] = ActsAsTaggableOn::Tag.find_all_by_name(config.catalogue["category_keywords"][c1]).map{|t| t.id}
        end
    end

    config.catalogue["keywords"].uniq!

  end

end