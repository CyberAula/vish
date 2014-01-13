source 'http://rubygems.org'

#gem 'rails', '~> 3.2.0'
gem 'rails', '3.2.14'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'
gem 'pg'
gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails', '~> 3.2.4'
gem 'bootstrap-sass'
gem 'coffee-rails'
gem 'uglifier', '>= 1.2.3'

gem 'jquery-rails', '>=2.0.2'
gem 'json', '1.7.4'
gem 'sinatra', '1.3.2'
gem 'selenium-webdriver', '=2.30.0'

git 'git://github.com/ging/social_stream.git', branch: "master" do
  gem 'social_stream-base'
  gem 'social_stream-documents'
  gem 'social_stream-linkser'
  gem 'social_stream-ostatus'
  gem 'social_stream-events'
end

# Force the first version of avatars_for_rails that does not collide with bootstrap
gem 'avatars_for_rails', '~> 1.1.0'

# Composite keys for vish-recsys
gem 'composite_primary_keys'

# We do not know the reasons for this gem:
#gem 'therubyracer'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
group :development do
  #Usage bundle exec unicorn -p 3000 -c config/unicorn.rb
  gem 'unicorn'
end

# Deploy with Capistrano
group :development do
  gem 'capistrano'
  #gem 'rvm-capistrano'
end

# Use god for its own purpose
gem 'god'

# Use exception notification
gem 'exception_notification', '=3.0.1'

# Be able to pass tests
gem 'rspec-rails', '=2.9.0'
gem 'net-ssh', '=2.4.0'

# Shortener
gem 'shortener'

gem 'rubyzip', '=0.9.9'

group :test do
  # Pretty printed test output
  gem 'factory_girl', '~> 2.6'
  gem 'capybara'
end

group :development do
  gem 'forgery'

  # Debug with Ruby 1.9.2
  # use with:
  # $ export VISH_DEBUG=true

  if ENV['VISH_DEV'] || ENV['VISH_DEBUG']	  	
    gem 'unicorn', '=4.6.2'
  end

end

gem 'pry-rails'

gem 'rest-client'

gem 'pdf-reader'

gem 'simple_captcha', :git => 'git://github.com/galetahub/simple-captcha.git'
gem 'delegates_attributes_to', :git => 'git://github.com/pahanix/delegates_attributes_to.git'

