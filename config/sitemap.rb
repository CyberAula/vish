# Set the host name for URL creation
# see https://github.com/kjvarga/sitemap_generator for documentation

SitemapGenerator::Sitemap.default_host = "http://" + Vish::Application.config.APP_CONFIG["domain"]
SitemapGenerator::Sitemap.sitemaps_path = 'sitemap/'
#do not include root, I will include it manually to indicate alternate lang
SitemapGenerator::Sitemap.include_root = false

class Lang_helper
  def self.alternates url, item
    if url.nil? || url==""
      return []
    end    
    locale_extension = url.include?("?") ? "&locale=" : "?locale=" 
    alts = []
    I18n.available_locales.each do |loc|
      alts.push({
        :href => url + locale_extension + loc.to_s,
        :lang => loc.to_s
      }) 
    end
    return alts    
  end
  
end

SitemapGenerator::Sitemap.create do  
  priorities = { "User" => 0.9,
                 "Excursion" => 1,
                 "Workshop" => 1,
                 "Event" => 0.1,
                 "Category" => 0.4,
                 "Document"=> 0.4, 
                 "Webapp"=> 0.8, 
                 "Scormfile"=> 0.8, 
                 "Link"=> 0.3, 
                 "Embed"=> 0.3
                }

  add('/', :alternates => Lang_helper.alternates("http://" + Vish::Application.config.APP_CONFIG["domain"], nil))
  

  VishConfig.getAllModelsInstances().each do |mod|
    prior = priorities[mod.model_name].nil? ? "0.5" : priorities[mod.model_name]
    mod.find_each do |instance|
      add polymorphic_path(instance), :lastmod => instance.updated_at, :changefreq => 'monthly', :priority => prior, :alternates => Lang_helper.alternates(polymorphic_url(instance), instance)
    end
  end

  User.find_each do |us|
      if !us.invitation_token.nil? && us.invitation_accepted_at.nil?
        next
      end
      add polymorphic_path(us), :lastmod => us.current_sign_in_at, :priority => priorities[User.model_name], :alternates => Lang_helper.alternates(polymorphic_url(us), us)
      #removed because google said these were not indexed (seen in the search console)
      #VishConfig.getAvailableMainModels.each do |tab|
      #  add polymorphic_path(us, :tab=>tab.pluralize.downcase), :lastmod => us.current_sign_in_at, :priority => priorities[User.model_name]
      #end
      #add polymorphic_path(us, :tab=>"followings"), :lastmod => us.current_sign_in_at, :priority => 0.1
      #add polymorphic_path(us, :tab=>"followers"), :lastmod => us.current_sign_in_at, :priority => 0.1
  end

  add '/search?browse=true&sort_by=popularity', :alternates => Lang_helper.alternates("http://" + Vish::Application.config.APP_CONFIG["domain"] +'/search?browse=true&sort_by=popularity', nil)
  add '/search?browse=true&sort_by=popularity&type=Excursion', :alternates => Lang_helper.alternates("http://" + Vish::Application.config.APP_CONFIG["domain"] +'/search?browse=true&sort_by=popularity&type=Excursion', nil)
  add '/search?browse=true&sort_by=popularity&type=User', :alternates => Lang_helper.alternates("http://" + Vish::Application.config.APP_CONFIG["domain"] +'/search?browse=true&sort_by=popularity&type=User', nil)
  add '/search?browse=true&sort_by=popularity&type=Resource', :alternates => Lang_helper.alternates("http://" + Vish::Application.config.APP_CONFIG["domain"] +'/search?browse=true&sort_by=popularity&type=Resource', nil)
  add '/search?browse=true&sort_by=popularity&type=Workshop', :alternates => Lang_helper.alternates("http://" + Vish::Application.config.APP_CONFIG["domain"] +'/search?browse=true&sort_by=popularity&type=Workshop', nil)
  add '/search?catalogue=true', :alternates => Lang_helper.alternates("http://" + Vish::Application.config.APP_CONFIG["domain"] +'/search?catalogue=true', nil)

  add '/contest', :alternates => Lang_helper.alternates("http://" + Vish::Application.config.APP_CONFIG["domain"]+ "/contest", nil)
  add '/overview', :alternates => Lang_helper.alternates("http://" + Vish::Application.config.APP_CONFIG["domain"] + "/overview", nil)
  add '/terms_of_use'

  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end
end
