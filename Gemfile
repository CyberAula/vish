source 'http://rubygems.org'

gem 'rails', '~> 3.2.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'
gem 'pg'
gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails', '~> 3.2.4'
gem 'bootstrap-sass'
gem 'coffee-rails', '~> 3.2.2'
gem 'uglifier', '>= 1.2.3'

gem 'jquery-rails', '>=2.0.2'
gem 'json', '1.7.4'
gem 'sinatra', '1.3.2'
gem 'selenium-webdriver', '=2.30.0'

gem 'social_stream-base', '~> 1.1.10'
gem 'social_stream-documents', '~> 1.1.3'
gem 'social_stream-linkser', '~> 1.1.1'
gem 'social_stream-ostatus', '~> 1.1.1'

# Force the first version of avatars_for_rails that does not collide with bootstrap
gem 'avatars_for_rails', '=0.2.8'

# Composite keys for vish-recsys
gem 'composite_primary_keys'

# We do not know the reasons for this gem:
#gem 'therubyracer'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
group :development do
  gem 'capistrano'
  gem 'rvm-capistrano'
end

# Use god for its own purpose
gem 'god'

# Use exception notification
gem 'exception_notification'

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

