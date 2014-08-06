Vish::Application.configure do
  
  #Init Catalogue
  config.after_initialize do
    config.catalogue_categories = ["art","biology","chemistry","citizenship","computerScience","economics","education","engineering","foreignLanguages","generalCulture","geography","geology","history","humanities","literature","maths","music","naturalScience","physics","technology"]
    config.default_categories = ["maths","physics","biology","technology"]
    combinedCategories = {"biology" => ["naturalScience","EnvironmentalStudies"], "engineering"=>["computerScience"], "generalCulture" => ["humanities","history","literature"], "humanities"=>["history","literature"], "naturalScience" => ["EnvironmentalStudies"], "technology"=>["engineering","computerScience"]}
    extraTerms = {"education"=>["eLearning","learning","teaching"],"maths"=>["math"]}

    #Build catalogue search terms
    config.catalogue = Hash.new
    config.catalogue_categories.each do |c1|
        config.catalogue[c1] = []

        allCategories = [c1]
        unless combinedCategories[c1].nil?
            allCategories.concat(combinedCategories[c1])
            allCategories.uniq!
        end

        allCategories.each do |c2|
            config.catalogue[c1].push(c2)
            I18n.available_locales.each do |lang|
                config.catalogue[c1].push(I18n.t("catalogue.categories." + c2, :locale => lang))
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
                if I18n.t("catalogue.extras." + c4, :locale => lang, :default => "translationMissing") != "translationMissing"
                    config.catalogue[c1].push(I18n.t("catalogue.extras." + c4, :locale => lang))
                end
            end
        end

        config.catalogue[c1].uniq!

        #Remove whitespaces
        config.catalogue[c1].map!{ |c5|
            c5.delete(' ')
        }
    end
  end

end