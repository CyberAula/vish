# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = Vish::Application.config.APP_CONFIG["domain"]

SitemapGenerator::Sitemap.create do
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

  VishConfig.getAllModels({:return_instances => true}).each do |mod|
    prior = priorities[mod.model_name].nil? ? "0.5" : priorities[mod.model_name]
    mod.find_each do |instance|
      add polymorphic_path(instance), :lastmod => instance.updated_at, :changefreq => 'monthly', :priority => prior
    end
  end

  User.find_each do |us|
      if !us.invitation_token.nil? && us.invitation_accepted_at.nil?
        next
      end
      add polymorphic_path(us), :lastmod => us.current_sign_in_at, :priority => priorities[User.model_name]
      VishConfig.getAvailableMainModels.each do |tab|
        add polymorphic_path(us, :tab=>tab.pluralize.downcase), :lastmod => us.current_sign_in_at, :priority => priorities[User.model_name]
      end
      add polymorphic_path(us, :tab=>"followings"), :lastmod => us.current_sign_in_at, :priority => 0.1
      add polymorphic_path(us, :tab=>"followers"), :lastmod => us.current_sign_in_at, :priority => 0.1
  end

  add '/search?browse=true&sort_by=popularity'
  add '/search?browse=true&sort_by=popularity&type=Excursion'
  add '/search?browse=true&sort_by=popularity&type=User'
  add '/search?browse=true&sort_by=popularity&type=Resource'
  add '/search?browse=true&sort_by=popularity&type=Workshop'
  add '/search?catalogue=true'

  add '/contest'
  add '/overview'
  add '/terms_of_use'
end
